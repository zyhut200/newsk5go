#!/usr/bin/expect

sudo yum install expect -y

# 设置超时时间，根据需要调整
set timeout 30

# 启动x-ui卸载脚本
spawn x-ui uninstall

# 等待卸载脚本的特定提示
expect "Are you sure you want to uninstall x-ui? (yes/no)"

# 自动响应 "yes"
send "yes\r"

# 等待任何其他可能的提示，并相应地发送响应
# ...

# 结束expect脚本
expect eof
