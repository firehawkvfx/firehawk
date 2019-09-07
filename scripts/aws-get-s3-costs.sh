echo 'get s3 costs for this month'

year=$(date +%Y)
next_year=$year
month=$(echo "$(date +%m)" | sed 's/^0*//')

next_month=$(($month + 1))

printf -v month "%02d" $month
printf -v next_month "%02d" $next_month

if [[ "$month" == "12" ]]; then
    next_year=$(($year+1))
    next_month=01
fi

# pad month
echo "month $month - $next_month"
echo "year $year - $next_year"

aws ce get-cost-and-usage \
    --time-period Start=2019-$month-01,End=2019-$next_month-01 \
    --granularity MONTHLY \
    --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" \
    --group-by Type=DIMENSION,Key=SERVICE Type=TAG,Key=Environment \
    --filter file://scripts/aws-get-s3-costs-filters.json