display_sleeping_bot() {
    cat << "EOF"

                                        ________
                            _________  |____/  /
                __________ |_____/  /      /  /____
               |______/  /      /  /       \ /_____|
                     /  /      /  /______
  _______________   /  /       \ /_______|
 |               | /  /______
 | ____ | | ____ | \ /_______|
 |  (_) | | (_)  |
 |      |_|      |
 |     _____     |
 |_______________|
EOF
}

keep_alive() {
    local start_time=$(date +%s);
    local stop_time=$((start_time + 18000));
    while ((start_time < stop_time)); do
        display_sleeping_bot;
        sleep 180;
        start_time=$(date +%s)
    done
}

keep_alive;
