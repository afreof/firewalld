# bash completion for firewall-cmd                         -*- shell-script -*-

# Copyright (C) 2013 Red Hat, Inc.
#
# Authors:
# Jiri Popelka <jpopelka@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


# TODO: find a way how to get the following options from firewall-cmd

OPTIONS_CONFIG="--get-zones --get-services --get-icmptypes"

OPTIONS_ZONE_INTERFACES="--list-interfaces --change-interface= --change-zone= \
                         --add-interface= --remove-interface= --query-interface= "
OPTIONS_ZONE_ACTION_ACTION="--add-service= --remove-service= --query-service= \
                       --add-port= --remove-port= --query-port= \
                       --add-icmp-block= --remove-icmp-block= --query-icmp-block= \
                       --add-forward-port= --remove-forward-port= --query-forward-port="
OPTIONS_ZONE_ADAPT_QUERY="--add-masquerade --remove-masquerade --query-masquerade \
                    --list-services --list-ports --list-icmp-blocks \
                    --list-forward-ports"
# these all can be used with/without preceding --zone=<zone>
OPTIONS_ZONE="${OPTIONS_ZONE_INTERFACES} --list-all \
              ${OPTIONS_ZONE_ACTION_ACTION} ${OPTIONS_ZONE_ADAPT_QUERY}"
# ${OPTIONS_ZONE_INTERFACES} can not be used after --permanent
# for example --permanent --zone=... --add-interface=...
# so the following is modified version of $OPTIONS_ZONE just for the specific --permanent use case
OPTIONS_PERMANENT_ZONE="${OPTIONS_ZONE_ACTION_ACTION} ${OPTIONS_ZONE_ADAPT_QUERY}"

# these can be used after --permanent
OPTIONS_PERMANENT="${OPTIONS_CONFIG} --zone= ${OPTIONS_PERMANENT_ZONE}"

OPTIONS_DIRECT="--passthrough \
                --add-chain --remove-chain --query-chain --get-chains \
                --add-rule --remove-rule --query-rule --get-rules"

# these all can be used as a "first" option
OPTIONS_GENERAL="--help --version \
                 --state --reload --complete-reload \
                 --enable-panic --disable-panic --query-panic \
                 --get-default-zone --set-default-zone= \
                 --get-active-zones --get-zone-of-interface= --list-all-zones \
                 ${OPTIONS_CONFIG} \
                 --zone= ${OPTIONS_ZONE} \
                 --permanent --direct"

_firewall_cmd()
{
    local cur prev words cword split
    _init_completion -s || return
    firewall-cmd --state 1> /dev/null || return

    case $prev in
    --zone|--set-default-zone)
        COMPREPLY=( $( compgen -W '`firewall-cmd --get-zones`' -- "$cur" ) )
        ;;
    --zone=*)
        if [[ ${words[@]} == *--permanent* ]]; then
            COMPREPLY=( $( compgen -W "${OPTIONS_PERMANENT_ZONE}" -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "${OPTIONS_ZONE}" -- "$cur" ) )
        fi
        ;;
    --*-service)
        COMPREPLY=( $( compgen -W '`firewall-cmd --get-services`' -- "$cur" ) )
        ;;
    --*-icmp-block)
        COMPREPLY=( $( compgen -W '`firewall-cmd --get-icmptypes`' -- "$cur" ) )
        ;;
    --add-service=*|--add-port=*|--add-icmp-block=*|--add-forward-port=*|--add-masquerade)
        COMPREPLY=( $( compgen -W "--timeout=" -- "$cur" ) )
        ;;
    --*-interface|--change-zone)
        _available_interfaces -a
        ;;
    --permanent)
        COMPREPLY=( $( compgen -W "${OPTIONS_PERMANENT}" -- "$cur" ) )
        ;;
    --direct)
        COMPREPLY=( $( compgen -W "${OPTIONS_DIRECT}" -- "$cur" ) )
        ;;
    --passthrough|--*-chain|--get-chains|--*-rule|--get-rules)
        COMPREPLY=( $( compgen -W 'ipv4 ipv6 eb' -- "$cur" ) )
        ;;
    ipv4|ipv6|eb)
        if [[ ${words[@]} == *--passthrough* ]]; then
            return 0
        else
            COMPREPLY=( $( compgen -W 'nat filter mangle' -- "$cur" ) )
        fi
        ;;      
    *)
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "${OPTIONS_GENERAL}" -- "$cur") )
        fi
        ;;
    esac

    # do not append a space to words that end with =
    [[ $COMPREPLY == *= ]] && compopt -o nospace

} &&
complete -F _firewall_cmd firewall-cmd
