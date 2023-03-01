#!/bin/bash
file_name=$1
echo "file_name:${file_name}"
from_line_no=$2
echo "from_line_no:${from_line_no}"
tail -n +${from_line_no} ${file_name} | while IFS="," read -r A B C;
do
    echo A:${A} B:${B} C:${C}
done
