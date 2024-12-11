abort() {
  echo "$@";
  exit 1;
}

check_variables() {
  if [ -z "$CRP" ]; then
      abort "-- Please enter the authcode from the given link.";
  elif [ ${#Pin} -lt 6 ]; then
      abort "-- Enter a PIN with 6 or more digits.";
  elif [ -z "${hostname}" ]; then
      abort "-- 'hostname' variable not found. Create a host first.";
  elif [ -z "${username}" ] || [ -z "${password}" ]; then
      abort "-- 'username' or 'password' variable not found. Create a user and set a password first.";
  else
      echo "-- Checked variables!";
  fi
}

is_installed() {
  sudo dpkg-query --list "$1" | grep -q "^ii" 2>/dev/null;
  return $?;
}

download_and_install() {
  curl -L -o "$2" "$1";
  sudo apt-get install --assume-yes --fix-broken "$2";
}

check_group() {
  grep -qE "^$1:" /etc/group 2>/dev/null;
  return $?;
}

check_service() {
  systemctl is-active --quiet "$1" 2>/dev/null;
  return $?;
}
#######################################################################

# Create Host and User
create_host_and_user() {
  echo "-----------------------------------------------";
  echo "-- Creating Host, User, and Setting them up ...";
  echo "-----------------------------------------------";
  sudo hostnamectl set-hostname "${hostname}"; # Creation of host
  sudo useradd -m "${username}"; # Creation of user
  sudo adduser "${username}" sudo; # Add user to sudo group
  echo "${username}:${password}" | sudo chpasswd; # Set password of user
  sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd; # Change default shell from sh to bash
  echo "-- Host, User created and configured having hostname '${hostname}', username '${username}', and password '${password}'.";
}

# Download and install Chrome Remote Desktop
installCRD() {
  echo "---------------------------------------";
  echo "-- Installing Chrome Remote Desktop ...";
  echo "---------------------------------------";
  ! is_installed chrome-remote-desktop && \
    download_and_install \
      https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb \
      /tmp/chrome-remote-desktop_current_amd64.deb;
  echo "-- Chrome Remote Desktop installation completed.";
}

# Install Desktop Environment
installDesktopEnvironment() {
  echo "-------------------------------------";
  echo "-- Installing Desktop Environment ...";
  echo "-------------------------------------";
  export DEBIAN_FRONTEND=noninteractive;
  sudo apt-get install --assume-yes xfce4 desktop-base dbus-x11 xfce4-terminal;
  sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session';
  sudo apt remove --assume-yes gnome-terminal;
  sudo apt-get install --assume-yes xscreensaver;
  ! is_installed lightdm && \
    sudo apt-get install --assume-yes lightdm && \
    sudo systemctl disable lightdm.service;
  echo "-- Desktop Environment installation completed.";
}

# Download and install Google Chrome
installGoogleChrome() {
  echo "-------------------------------";
  echo "-- Installing Google Chrome ...";
  echo "-------------------------------";
  ! is_installed google-chrome-stable && \
    download_and_install \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      /tmp/google-chrome-stable_current_amd64.deb;
  echo "-- Google Chrome installation completed.";
}

# Finish
finish() {
  echo "-----------------";
  echo "-- Finalizing ...";
  echo "-----------------";
  ! check_group chrome-remote-desktop && \
    sudo addgroup chrome-remote-desktop;
  sudo adduser "${username}" chrome-remote-desktop;
  command="${CRP} --pin=${Pin}";
  sudo -u "$(whoami)" bash -c "${command}";
  ! check_service chrome-remote-desktop.service && \
    sudo service chrome-remote-desktop start 2>/dev/null;
  echo "-- Finished Successfully.";
}

# Do all the work!
WorkNow() {
    local SCRIPT_VERSION="20230620";
    echo "$0, v$SCRIPT_VERSION";
    local START=$(date);
    check_variables "$@";
    create_host_and_user;
    echo "-----------------------------------------";
    echo "-- It takes 4-5 minutes for installation.";
    echo "-----------------------------------------";
    sudo apt-get update;
    installCRD;
    installDesktopEnvironment;
    installGoogleChrome;
    finish;
    if [ "$?" = "0" ]; then
        echo "-----------------------------------------------------------------------------------";
        echo "-- RDP created and successfully moved to 'https://remotedesktop.google.com/access'.";
        echo "-----------------------------------------------------------------------------------";
    else
        abort "-- Error occurred!";
    fi
    local STOP=$(date);
    echo "-- Start time: $START --";
    echo "-- Stop time: $STOP --";
    exit 0;
}

# --- main() ---
WorkNow "$@";
# --- end main() ---
