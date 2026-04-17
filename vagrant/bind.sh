# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.

#shortened
alias brupd="sudo bridge_updater -c /etc/brupd_conf.json -l info"
alias ipcheck="all_proxy=socks5h://127.0.0.1:9050 curl -s https://check.torproject.org/api/ip | jq -r '.IP'"
alias status="sudo systemctl status tor@default --no-pager"
alias restart="sudo systemctl restart tor@default"
alias journal="sudo journalctl -e -u tor@default"
alias bridges="echo && sudo tail -n +1 /etc/tor/torrc.d/* | grep --color=always -E '^==> .* <==|$'"

brupd-tor(){
    git config --global http.proxy socks5h://127.0.0.1:9050
    git config --global https.proxy socks5h://127.0.0.1:9050

    sudo -E all_proxy=socks5h://127.0.0.1:9050 bridge_updater -c /etc/brupd_conf.json -l info "$@"

    git config --global --unset http.proxy
    git config --global --unset https.proxy
}

print-service-mode(){

    local lang=${1:-en}

    if [[ $lang == "ru" ]]; then

        local tormsg="brupd сейчас работает через tor (brupd-tor.timer активен)"
        local stdmsg="brupd сейчас работает напрямую (brupd.timer активен)"

    elif [[ $lang == "en" ]]; then

        local tormsg="brupd is currently working through tor (brupd-tor.timer is active)"
        local stdmsg="brupd is currently working directly (brupd.timer is active)"
    
    else
        echo "Unsupported language. Supported languages: en, ru"
        return
    fi

    if systemctl is-active --quiet brupd-tor.timer; then
        echo -e "\e[38;5;51m$tormsg\033[0m"
    elif systemctl is-active --quiet brupd.timer; then
        echo -e "\e[38;5;51m$stdmsg\033[0m"
    else
        echo -e "\e[38;5;196mbrupd service is not active\033[0m"
    fi

}

reconfigure-daemon(){

    if [[ $1 == "tor" ]]; then

        sudo systemctl disable --now brupd.timer > /dev/null 2>&1
        sudo systemctl enable --now brupd-tor.timer > /dev/null 2>&1

        sleep 5

        return
    fi

    if [[ $1 == "std" ]]; then

        sudo systemctl disable --now brupd-tor.timer > /dev/null 2>&1
        sudo systemctl enable --now brupd.timer > /dev/null 2>&1

        sleep 5

        return
    fi

    echo -e "Usage: \e[38;5;51mreconfigure-daemon [tor|std]\033[0m"
}

brupd-info(){

    if [[ $1 == "ru" ]]; then

        clear

        echo -e "\nПривет от jolyne-nyah. Ниже представлены полезные команды и важная информация.\n"
        echo -e "Чтобы увидеть это сообщение на английском: \e[38;5;51mbrupd-info en\033[0m"
        echo -e "Чтобы увидеть это сообщение на русском:    \e[38;5;51mbrupd-info ru\033[0m\n"

        echo -e "Инфо: мосты tor обновляются каждый час автоматически с помощью systemd таймера."
        echo -e "Инфо: Tor прокси работает на \e[38;5;51m127.0.0.1:6969\033[0m на хосте, ты можешь настроить его в своем браузере для теста соединения."
        echo -e "Инфо: на данный момент поддерживаются только vanilla и obfs4 мосты"

        echo -e "\n===Использование вручную===\n"
        
        echo -e "1.  Чтобы проверить конфиг:                                             \e[38;5;51mbrupd check\033[0m"
        echo -e "2.  Чтобы получить новые мосты без перезагрузки tor:                    \e[38;5;51mbrupd fetch\033[0m"
        echo -e "3.  Чтобы записать полученные мосты в конфиг tor и перезагрузить tor:   \e[38;5;51mbrupd write\033[0m"
        echo -e "4.  fetch + write в одну команду:                                       \e[38;5;51mbrupd update\033[0m\n"

        echo -e "5.  Чтобы выполнить любую команду только для секции direct или repos, используй флаги \e[38;5;51m-d\033[0m и \e[38;5;51m-r\033[0m соответственно."
        echo -e "    Примеры: \e[38;5;51mbrupd fetch -d\033[0m, \e[38;5;51mbrupd update -r\033[0m\n"

        echo -e "6.  Чтобы игнорировать проверки наличия подключения к интернету, используй флаг \e[38;5;51m-i\033[0m"
        echo -e "    Примеры: \e[38;5;51mbrupd update -i\033[0m, \e[38;5;51mbrupd check -i\033[0m\n"

        echo -e "7.  Чтобы запустить \e[38;5;51mbrupd\033[0m через tor прокси, используй команду \e[38;5;51mbrupd-tor\033[0m вместо \e[38;5;51mbrupd\033[0m"
        echo -e "    Пример: \e[38;5;51mbrupd-tor update -i\033[0m\n"

        echo -e "8.  Увидеть сетевой монитор:           \e[38;5;51msudo nyx\033[0m\n"

        echo -e "9.  Посмотреть ip выходного узла tor:  \e[38;5;51mipcheck\033[0m\n"

        echo -e "10. Посмотреть текущие мосты:          \e[38;5;51mbridges\033[0m\n"

        echo -e "11. Переконфигурировать brupd-службу для работы через tor или напрямую: \e[38;5;51mreconfigure-daemon [tor|std]\033[0m"
        echo -e "    Пример: \e[38;5;51mreconfigure-daemon tor\033[0m"
        echo -e "    (По умолчанию уже настроена на работу через tor)\n"

        echo -e "12. Посмотреть режим работы службы brupd: \e[38;5;51mprint-service-mode [en|ru]\033[0m\n"

        echo -e "13. Команды для tor service:"
        echo -e "    Статус:     \e[38;5;51mstatus\033[0m"
        echo -e "    Перезапуск: \e[38;5;51mrestart\033[0m"
        echo -e "    Журнал:     \e[38;5;51mjournal\033[0m\n"

        echo -e "Наслаждайся. \n"
    fi
    
    if [[ $1 == "en" ]]; then
    
        clear

        echo -e "\nHi hi from jolyne-nyah. I have some necessary info and helpful commands for you.\n"
        echo -e "To see this message in russian, run: \e[38;5;51mbrupd-info ru\033[0m"
        echo -e "To see this message in english, run: \e[38;5;51mbrupd-info en\033[0m\n"

        echo -e "Info: Tor bridges are updated every hour automatically by a systemd timer."
        echo -e "Info: Tor proxy is running on \e[38;5;51m127.0.0.1:6969\033[0m on your host, you can set it up in your browser to test the connection."
        echo -e "Info: currently only vanilla and obfs4 bridges are supported"

        echo -e "\n===Manual Usage===\n"
        
        echo -e "1.  To check the configuration file, run:                                           \e[38;5;51mbrupd check\033[0m"
        echo -e "2.  To fetch new bridges without tor reconfiguring, run:                            \e[38;5;51mbrupd fetch\033[0m"
        echo -e "3.  To write fetched bridges to the tor config file and reload tor, run:            \e[38;5;51mbrupd write\033[0m"
        echo -e "4.  to fetch + write in one command, run:                                           \e[38;5;51mbrupd update\033[0m\n"

        echo -e "5.  To run any command for direct links or repos only, use flags \e[38;5;51m-d\033[0m or \e[38;5;51m-r\033[0m respectively."
        echo -e "    Examples: \e[38;5;51mbrupd fetch -d\033[0m, \e[38;5;51mbrupd update -r\033[0m\n"

        echo -e "6.  To ignore internet connectivity checks, use flag \e[38;5;51m-i\033[0m"
        echo -e "    Examples: \e[38;5;51mbrupd update -i\033[0m, \e[38;5;51mbrupd check -i\033[0m\n"

        echo -e "7.  To run \e[38;5;51mbrupd\033[0m through tor proxy, use command \e[38;5;51mbrupd-tor\033[0m instead of \e[38;5;51mbrupd\033[0m"
        echo -e "    Example: \e[38;5;51mbrupd-tor update -i\033[0m\n"

        echo -e "8.  To see the network monitor, run:       \e[38;5;51msudo nyx\033[0m\n"
        
        echo -e "9.  To check your tor exit node ip, run:   \e[38;5;51mipcheck\033[0m\n"

        echo -e "10. To see current bridges, run:           \e[38;5;51mbridges\033[0m\n"

        echo -e "11. To reconfigure the brupd-daemon to work through tor or directly, run: \e[38;5;51mreconfigure-daemon [tor|std]\033[0m"
        echo -e "    Example: \e[38;5;51mreconfigure-daemon tor\033[0m"
        echo -e "    (By default it's already set up to work through tor)\n"

        echo -e "12. To see the service mode, run: \e[38;5;51mprint-service-mode [en|ru]\033[0m\n"

        echo -e "13. Some commands for tor service:"
        echo -e "    Status:     \e[38;5;51mstatus\033[0m"
        echo -e "    Restart:    \e[38;5;51mrestart\033[0m"
        echo -e "    Journal:    \e[38;5;51mjournal\033[0m\n"

        echo -e "Enjoy. \n"
    fi
}

brupd-info en
