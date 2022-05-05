#!/bin/bash

capitech_user=$1
capitech_password=$2
departmentId=$3
projectId=$4
subProjectId=$5

from_year="$(date +'%Y')"
current_year="$(date +'%Y')"
current_day="$(date +'%0d')"
current_month="$(date +'%0m')"
day_of_week="$(date +'%u')"
next_day="$(bc <<< "$current_day + 1")"

if [ "${day_of_week#0}"  -gt 5 ];then # remove prepended zero of day_of_week
	echo "Not a weekday, skipping..." 
	exit 0
fi

if [ "${day_of_week#0}" = '1' ];then # remove prepended zero of day_of_week
	yesterday="$(("${current_day#0} - 3"))"
else
	yesterday="$(("${current_day#0} - 1"))"
fi

if [ "$current_day" -gt 24 ];then
	last_month="$current_month"
else
	if [ "$current_month" -lt 2 ];then
		last_month=12
		from_year="$(bc <<< "$current_year - 1")"
	else
		last_month="$(bc <<< "$(date +%m) - 1")"
		if [ "$last_month" -lt 10 ];then
			last_month="0$last_month"
		fi
	fi
fi

access_token=''
refresh_token=''

capitech_authorize()
{
	authorized="$(curl 'https://flow.capitech.no/bcc/api/public/v1/Webtid/authorize' \
		-H 'Sec-Fetch-Mode: cors' \
		-H 'Sec-Fetch-Site: same-origin' \
		-H 'Origin: https://flow.capitech.no' \
		-H 'Accept-Encoding: gzip, deflate, br' \
		-H 'Accept-Language: en-US,en;q=0.9' \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36' \
		-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Referer: https://flow.capitech.no/bcc/apps/MinCapitech/index.htm?v=15.9.0.337' \
		-H 'X-Requested-With: XMLHttpRequest' \
		-H 'Cookie: my-capitech-remember-me=""; my-capitech-clientid=100' \
		--data-urlencode "username=$capitech_user" \
		--data-urlencode "password=$capitech_password" \
		--data "clientId=100" \
		--compressed 2> /dev/null | jq '.content[0]')"
	echo $authorized
	refresh_token="$(jq '.refreshToken' <<< "$authorized")"
	access_token="$(jq '.accessToken' <<< "$authorized")"
}

get_hours()
{
	no_quote_access_token="$(tr -d '"' <<< "$access_token")"
	curl 'https://flow.capitech.no/bcc/api/public/v1/Webtid/getAccumulatedTime' \
		-v \
		-H 'Sec-Fetch-Mode: cors' \
		-H 'Sec-Fetch-Site: same-origin' \
		-H 'Origin: https://flow.capitech.no' \
		-H 'Accept-Encoding: gzip, deflate, br' \
		-H 'Accept-Language: en-US,en;q=0.9' \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36' \
		-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Referer: https://flow.capitech.no/bcc/apps/MinCapitech/dashboard.htm?v=15.9.0.337' \
		-H 'X-Requested-With: XMLHttpRequest' \
		-H "Cookie: my-capitech-remember-me=\"\"; my-capitech-clientid=100; my-capitech-refresh-token=$refresh_token; my-capitech-access-token=$access_token" \
		--data "accessToken=$no_quote_access_token&fromDate=$from_year-$last_month-25&toDate=$current_year-$current_month-$current_day" \
		--compressed 2> /dev/null
	}


register_today()
{
	no_quote_access_token="$(tr -d '"' <<< "$access_token")"

	curl 'https://flow.capitech.no/bcc/api/public/v1/Webtid/createCustomTimeTransaction' \
		-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0' \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		--compressed \
		-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
		-H 'X-Requested-With: XMLHttpRequest' \
		-H 'Origin: https://flow.capitech.no' \
		-H 'DNT: 1' \
		-H 'Connection: keep-alive' \
		-H 'Referer: https://flow.capitech.no/bcc/apps/MinCapitech/dashboard.htm?v=15.10.1+372' \
		-H 'Cookie: my-capitech-clientid=100; my-capitech-remember-me=true; my-capitech-refresh-token='"$refresh_token"'; my-capitech-access-token='"$access_token" \
		-H 'Sec-GPC: 1' \
		--data-raw 'accessToken='"$no_quote_access_token"'&dateIn='$current_year'-'$current_month'-'$current_day'&timeIn=09%3A00&dateOut='$current_year'-'$current_month'-'$current_day'&timeOut=17%3A00&departmentId='$departmentId'&projectId='$projectId'&subProjectId='$subProjectId'&text=' 2> /dev/null | jq
	}

capitech_authorize
sleep .1
register_today

echo "registered todays capitech entry"
read -p "exit: press enter" a
