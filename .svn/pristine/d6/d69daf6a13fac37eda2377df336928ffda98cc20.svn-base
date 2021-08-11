"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LinuxInstaller = void 0;
const os = require("os");
const path = require("path");
const child_process = require("child_process");
const fs = require("fs-extra");
const si = require("systeminformation");
const semver = require("semver");
class LinuxInstaller {
    constructor(hbService) {
        this.hbService = hbService;
    }
    get runPartsPath() {
        return path.resolve('/etc/hb-service', this.hbService.serviceName.toLowerCase(), 'prestart.d');
    }
    async install() {
        this.checkForRoot();
        await this.checkUser();
        this.setupSudo();
        await this.hbService.portCheck();
        await this.hbService.storagePathCheck();
        await this.hbService.configCheck();
        try {
            await this.createRunPartsPath();
            await this.enableService();
            await this.hbService.printPostInstallInstructions();
        }
        catch (e) {
            console.error(e.toString());
            this.hbService.logger(`ERROR: Failed Operation`, 'fail');
        }
    }
    async uninstall() {
        this.checkForRoot();
        await this.stop();
        await this.disableService();
    }
    async start() {
        this.checkForRoot();
        try {
            this.hbService.logger(`Starting ${this.hbService.serviceName} Service...`);
            child_process.execSync(`/etc/init.d/homebridge start`);
            this.hbService.logger(`${this.hbService.serviceName} Started`, 'succeed');
        }
        catch (e) {
            this.hbService.logger(`Failed to start ${this.hbService.serviceName}`, 'fail');
        }
    }
    async stop() {
        this.checkForRoot();
        try {
            this.hbService.logger(`Stopping ${this.hbService.serviceName} Service...`);
            child_process.execSync(`/etc/init.d/homebridge stop`);
            this.hbService.logger(`${this.hbService.serviceName} Stopped`, 'succeed');
        }
        catch (e) {
            this.hbService.logger(`Failed to stop homebridge`, 'fail');
        }
    }
    async restart() {
        this.checkForRoot();
        try {
            this.hbService.logger(`Restarting ${this.hbService.serviceName} Service...`);
            child_process.execSync(`/etc/init.d/homebridge restart`);
            this.hbService.logger(`${this.hbService.serviceName} Restarted`, 'succeed');
        }
        catch (e) {
            this.hbService.logger(`Failed to restart ${this.hbService.serviceName}`, 'fail');
        }
    }
    async rebuild(all = false) {
        this.hbService.logger(`You cannot rebuild in the Openwrt.`);
    }
    async getId() {
        if (process.getuid() === 0 && this.hbService.asUser) {
            const uid = child_process.execSync(`id -u ${this.hbService.asUser}`).toString('utf8');
            const gid = child_process.execSync(`id -g ${this.hbService.asUser}`).toString('utf8');
            return {
                uid: parseInt(uid, 10),
                gid: parseInt(gid, 10),
            };
        }
        else {
            return {
                uid: os.userInfo().uid,
                gid: os.userInfo().gid,
            };
        }
    }
    getPidOfPort(port) {
        try {
            if (this.hbService.docker) {
                return child_process.execSync(`pidof homebridge`).toString('utf8').trim();
            }
            else {
                return child_process.execSync(`fuser ${port}/tcp 2>/dev/null`).toString('utf8').trim();
            }
        }
        catch (e) {
            return null;
        }
    }
    async updateNodejs(job) {
        this.hbService.logger(`You cannot update Nodejs in the Openwrt.`);
    }
    async updateNodeFromTarball(job, targetPath) {
        this.hbService.logger(`You cannot update Nodejs in the Openwrt.`);
    }
    async updateNodeFromNodesource(job) {
        this.hbService.logger(`You cannot update Nodejs in the Openwrt.`);
    }
    async enableService() {
        try {
            child_process.execSync(`/etc/init.d/homebridge enable 2> /dev/null`);
        }
        catch (e) {
            this.hbService.logger(`WARNING: failed to run "enable homebridge"`, 'warn');
        }
    }
    async disableService() {
        try {
            child_process.execSync(`/etc/init.d/homebridge disable 2> /dev/null`);
        }
        catch (e) {
            this.hbService.logger(`WARNING: failed to run "disable homebridge"`, 'warn');
        }
    }
    checkForRoot() {
        if (process.getuid() !== 0) {
            this.hbService.logger('ERROR: This command must be executed using sudo on Linux', 'fail');
            this.hbService.logger(`EXAMPLE: sudo hb-service ${this.hbService.action}`, 'fail');
            process.exit(1);
        }
        if (this.hbService.action === 'install' && !this.hbService.asUser) {
            this.hbService.logger('ERROR: User parameter missing. Pass in the user you want to run Homebridge as using the --user flag eg.', 'fail');
            this.hbService.logger(`EXAMPLE: sudo hb-service ${this.hbService.action} --user your-user`, 'fail');
            process.exit(1);
        }
    }
    async checkUser() {
        try {
            child_process.execSync(`id ${this.hbService.asUser} 2> /dev/null`);
        }
        catch (e) {
            this.hbService.logger(`WARNING: The ${this.hbService.asUser} user does not exist.`);
        }
    }
    setupSudo() {
        try {
            const sudoersEntry = `${this.hbService.asUser}    ALL=(ALL) NOPASSWD:SETENV: /etc/init.d/homebridge, /sbin/halt, /sbin/reboot, /sbin/poweroff, /sbin/logread, /usr/bin/npm`;
            const sudoers = fs.readFileSync('/etc/sudoers', 'utf-8');
            if (sudoers.includes(sudoersEntry)) {
                return;
            }
            child_process.execSync(`echo '${sudoersEntry}' | sudo EDITOR='tee -a' visudo`);
        }
        catch (e) {
            this.hbService.logger('WARNING: Failed to setup /etc/sudoers, you may not be able to shutdown/restart your server from the Homebridge UI.', 'warn');
        }
    }
    async createRunPartsPath() {
        await fs.mkdirp(this.runPartsPath);
        const permissionScriptPath = path.resolve(this.runPartsPath, '10-fix-permissions');
        const permissionScript = [
            `#!/bin/sh`,
            ``,
            `# Ensure the storage path permissions are correct`,
            `if [ -n "$UIX_STORAGE_PATH" ] && [ -n "$USER" ]; then`,
            `  echo "Ensuring $UIX_STORAGE_PATH is owned by $USER"`,
            `  [ -d $UIX_STORAGE_PATH ] || mkdir -p $UIX_STORAGE_PATH`,
            `  chown -R $USER: $UIX_STORAGE_PATH`,
            `fi`,
        ].filter(x => x !== null).join('\n');
        await fs.writeFile(permissionScriptPath, permissionScript);
        await fs.chmod(permissionScriptPath, '755');
    }
}
exports.LinuxInstaller = LinuxInstaller;
//# sourceMappingURL=linux.js.map
