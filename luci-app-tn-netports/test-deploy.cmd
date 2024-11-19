@echo off

set LUCI_LUASRC_PATH=/usr/lib/lua/5.1/luci
set LUCI_HTDOCS_PATH=/www
set LUCI_ROOT_PATH=/

set HOST=%1
set PASSWORD=%2
set EXTRA_OPTIONS=

if NOT [%PASSWORD%] == [] (
	set EXTRA_OPTIONS=-pw "%PASSWORD%"
)

if [%HOST%] == [] goto host_empty

IF EXIST %~dp0/luasrc (
	pscp -r %EXTRA_OPTIONS% %~dp0/luasrc/* %HOST%:%LUCI_LUASRC_PATH%
)

IF EXIST %~dp0/htdocs (
	pscp -r %EXTRA_OPTIONS% %~dp0/htdocs/* %HOST%:%LUCI_HTDOCS_PATH%
)

IF EXIST %~dp0/root (
	pscp -r %EXTRA_OPTIONS% %~dp0/root/* %HOST%:%LUCI_ROOT_PATH%
)

rem Clear LuCI index cache
plink %EXTRA_OPTIONS% %HOST% "/etc/init.d/uhttpd stop; rm -rf /tmp/luci-*; /etc/init.d/uhttpd start"

echo Success
goto done

:host_empty
echo Usage: %0 [user@]host [password]

:done
