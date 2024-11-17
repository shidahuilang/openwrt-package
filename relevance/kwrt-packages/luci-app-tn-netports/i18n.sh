#!/bin/sh

mkdir -p po/templates

i18n-scan.pl . > po/templates/netports.pot
i18n-update.pl po
