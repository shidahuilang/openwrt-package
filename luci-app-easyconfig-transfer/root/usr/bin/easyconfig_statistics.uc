#!/usr/bin/ucode
'use strict';

//
// (c) 2023 Cezary Jackiewicz <cezary@eko.one.pl>
//

import { readfile, writefile } from "fs";

let filename = `/tmp/easyconfig_statistics.json`;

let MAC = shift(ARGV);
let IFNAME = shift(ARGV);
let TX = shift(ARGV);
let RX = shift(ARGV);
let CONNECTED = shift(ARGV);
let DHCPNAME = shift(ARGV);
let TYPE = shift(ARGV);

if (!MAC || !IFNAME || !TYPE) {
	warn("Usage: easyconfig_statistics.uc <MAC> <IFNAME> <TX> <RX> <CONNECTED> <DHCPNAME> <TYPE>\n");
	exit(1);
}

// compatibility with old scripts
MAC = replace(MAC, /:/g, "_");

if (!CONNECTED)
	CONNECTED = 0;
if (!TX)
	TX = 0;
if (!RX)
	RX = 0;

TX = int(TX);
RX = int(RX);
TYPE = int(TYPE);
CONNECTED = int(CONNECTED);

let ts = localtime();
let day = sprintf("%04d%02d%02d", ts.year, ts.mon, ts.mday);
let ts_now = sprintf("%04d%02d%02d%02d%02d", ts.year, ts.mon, ts.mday, ts.hour, ts.min);

let db = {};
let content = readfile(filename);
if (content) {
	try { db = json(content); }
	catch { db = {}; }
}

let tmp = null;

if (IFNAME == "init") {
	for (let key1 in db) {
		if (type(db[key1]) == "object") {
			for (let key2 in db[key1]) {
				if (type(db[key1][key2]) == "object") {
					db[key1][key2].last_tx = 0;
					db[key1][key2].last_rx = 0;
				}
			}
		}
	}
	writefile(filename, db);
	exit(0)
}

if (IFNAME == "delete") {
	tmp = db[MAC];
	if (tmp) {
		delete db[MAC];
		writefile(filename, db);
	}
	exit(0)
}

tmp = db[MAC];
if (!tmp) {
	db[MAC] = {};
	db[MAC].first_seen = ts_now;
}

if (DHCPNAME)
	db[MAC].dhcpname = DHCPNAME;

db[MAC].type = TYPE;

tmp = db[MAC][IFNAME];
if (!tmp) {
	db[MAC][IFNAME] = {};
	db[MAC][IFNAME].last_tx = 0;
	db[MAC][IFNAME].last_rx = 0;
	db[MAC][IFNAME].first_seen = ts_now;
}
let last_tx = int(db[MAC][IFNAME].last_tx);
let last_rx = int(db[MAC][IFNAME].last_rx);

tmp = db[MAC][IFNAME][day];
if (!tmp) {
	db[MAC][IFNAME][day] = {};
	db[MAC][IFNAME][day].total_tx = 0;
	db[MAC][IFNAME][day].total_rx = 0;
}
let total_tx = int(db[MAC][IFNAME][day].total_tx);
let total_rx = int(db[MAC][IFNAME][day].total_rx);

let dtx = TX - last_tx;
if (dtx < 0)
	dtx = TX;

let drx = RX - last_rx;
if (drx < 0)
	drx = RX;

if (CONNECTED <= 60) {
	dtx = TX;
	drx = RX;
}

db[MAC][IFNAME][day].total_tx = total_tx + dtx;
db[MAC][IFNAME][day].total_rx = total_rx + drx;
db[MAC][IFNAME].last_tx = TX;
db[MAC][IFNAME].last_rx = RX;
db[MAC][IFNAME].last_seen = ts_now;
db[MAC].last_seen = ts_now;

writefile(filename, db);

exit(0);
