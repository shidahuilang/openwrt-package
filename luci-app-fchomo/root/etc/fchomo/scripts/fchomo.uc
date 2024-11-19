/* thanks for homeproxy */

import { mkstemp, popen } from 'fs';

/* Global variables START */
export const HM_DIR = '/etc/fchomo';
export const RUN_DIR = '/var/run/fchomo';
export const PRESET_OUTBOUND = [
	'DIRECT',
	'REJECT',
	'REJECT-DROP',
	'PASS',
	'COMPATIBLE'
];
/* Global variables END */

/* Utilities start */
/* Kanged from luci-app-commands */
export function shellQuote(s) {
	return `'${replace(s, "'", "'\\''")}'`;
};

export function yqRead(flags, command, filepath) {
	let out = '';

	const fd = popen(`yq ${flags} ${shellQuote(command)} ${filepath}`);
	if (fd) {
		out = fd.read('all');
		fd.close();
	}

	return out;
};
/* Utilities end */

/* String helper start */
export function isEmpty(res) {
	return !res || res === 'nil' || (type(res) in ['array', 'object'] && length(res) === 0);
};

export function strToBool(str) {
	return (str === '1') || null;
};

export function strToInt(str) {
	if (isEmpty(str))
		return null;

	return !match(str, /^\d+$/) ? str : int(str) ?? null;
};

export function durationToSecond(str) {
	if (isEmpty(str))
		return null;

	let seconds = 0;
	let arr = match(str, /^(\d+)(s|m|h|d)?$/);
	if (arr) {
		if (arr[2] === 's') {
			seconds = strToInt(arr[1]);
		} else if (arr[2] === 'm') {
			seconds = strToInt(arr[1]) * 60;
		} else if (arr[2] === 'h') {
			seconds = strToInt(arr[1]) * 3600;
		} else if (arr[2] === 'd') {
			seconds = strToInt(arr[1]) * 86400;
		} else
			seconds = strToInt(arr[1]);
	}

	return seconds;
};

export function arrToObj(res) {
	if (isEmpty(res))
		return null;

	let object;
	if (type(res) === 'array') {
		object = {};
		map(res, (e) => {
			if (type(e) === 'array')
				object[e[0]] = e[1];
		});
	} else
		return res;

	return object;
};

export function removeBlankAttrs(res) {
	let content;

	if (type(res) === 'object') {
		content = {};
		map(keys(res), (k) => {
			if (type(res[k]) in ['array', 'object'])
				content[k] = removeBlankAttrs(res[k]);
			else if (res[k] !== null && res[k] !== '')
				content[k] = res[k];
		});
	} else if (type(res) === 'array') {
		content = [];
		map(res, (k, i) => {
			if (type(k) in ['array', 'object'])
				push(content, removeBlankAttrs(k));
			else if (k !== null && k !== '')
				push(content, k);
		});
	} else
		return res;

	return content;
};
/* String helper end */
