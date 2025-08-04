@echo off
title AI OS - WSL
echo 🚀 Starting AI OS from Windows...
cd /d "\\wsl$\Ubuntu\home\Projects\SEO\AIOS"
wsl bash -c "cd /home/Projects/SEO/AIOS && ./start.sh"
pause
