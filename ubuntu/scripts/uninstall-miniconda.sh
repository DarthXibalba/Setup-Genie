#!/bin/bash
rm -rf ~/miniconda3

echo "Find and delete the lines between:"
echo "# >>> conda initialize >>>"
echo "# <<< conda initialize <<<"

read -p "Press any key to continue..."

vim ~/.bashrc
