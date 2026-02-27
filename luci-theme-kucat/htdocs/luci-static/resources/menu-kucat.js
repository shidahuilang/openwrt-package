/*
 *  luci-theme-kucat
 *  Copyright (C) 2022-2026 The Sirpdboy <herboy2008@gmail.com> 
 *
 *  Licensed to the public under the Apache License 2.0
 */

'use strict';
'require baseclass';
'require ui';
'require fs';

// 抑制控制台警告
(function() {
    const originalConsoleWarn = console.warn;
    const originalConsoleError = console.error;
    const originalConsoleLog = console.log;
    
    console.warn = function(...args) {
        const message = args.join(' ');
        const ignoredWarnings = [
            'X-Frame-Options may only be set',
            'Added non-passive event listener',
            'Direct use XHR() is deprecated'
        ];
        
        if (ignoredWarnings.some(w => message.includes(w))) {
            return;
        }
        originalConsoleWarn.apply(console, args);
    };
    
    console.debug = function(...args) {
        if (localStorage.getItem('debug') === 'true') {
            originalConsoleLog.apply(console, ['[DEBUG]', ...args]);
        }
    };
})();

/**
 * Lightweight animation utilities for menu interactions
 */
const KucatAnimations = {
    durations: {
        fast: 100,
        normal: 200,
        slow: 400
    },

    slideDown: function(element, duration = 'normal') {
        if (!element) return;
        
        const animDuration = typeof duration === 'string' ? 
            this.durations[duration] || this.durations.normal : 
            duration;
        
        const originalDisplay = element.style.display;
        const originalHeight = element.style.height;
        
        element.style.display = 'block';
        element.style.overflow = 'hidden';
        element.style.height = '0px';
        element.style.transition = `height ${animDuration}ms ease-out`;
        
        requestAnimationFrame(() => {
            element.style.height = element.scrollHeight + 'px';
        });
        
        setTimeout(() => {
            element.style.height = originalHeight;
            element.style.overflow = '';
            element.style.transition = '';
            if (originalDisplay === 'none') {
                element.style.display = 'block';
            }
        }, animDuration);
    },

    slideUp: function(element, duration = 'normal') {
        if (!element) return;
        
        const animDuration = typeof duration === 'string' ? 
            this.durations[duration] || this.durations.normal : 
            duration;
        
        const originalHeight = element.style.height;
        
        element.style.overflow = 'hidden';
        element.style.height = element.scrollHeight + 'px';
        element.style.transition = `height ${animDuration}ms ease-out`;
        
        requestAnimationFrame(() => {
            element.style.height = '0px';
        });
        
        setTimeout(() => {
            element.style.display = 'none';
            element.style.height = originalHeight;
            element.style.overflow = '';
            element.style.transition = '';
        }, animDuration);
    }
};

return baseclass.extend({
    // Menu icons mapping
    menuIcons: {
        'status': 'status',
        'system': 'system',
        'services': 'services',
        'network': 'network',
        'netwizard': 'netwizard',
        'docker': 'docker',
        'vpn': 'vpn',
        'nas': 'nas',
        'control': 'control'
    },
    defaultIcon: 'default',
    
    // Menu categories - 将从配置加载
    menuCategories: {
        basic: []
    },
    
    currentCategory: 'basic',
    menuRendered: false,

    __init__: function() {
        try {
            this.loadSavedCategory();
            // 先加载菜单配置，再加载菜单树
            this.loadMenuConfig().then(() => {
                ui.menu.load().then(L.bind(this.render, this));
            });
        } catch (e) {
            console.debug('Init error:', e);
        }
    },

    /**
     * 从UCI配置加载basic菜单列表
     */
    loadMenuConfig: function() {
        return new Promise((resolve) => {
            // 尝试从配置文件读取
            fs.read('/etc/config/kucat').then((content) => {
                var basicMenus = [];
                var lines = content.split('\n');
                lines.forEach(line => {
                    var match = line.match(/list item ['"](.+)['"]/);
                    if (match) {
                        basicMenus.push(match[1]);
                    }
                });
                
                if (basicMenus.length > 0) {
                    this.menuCategories.basic = basicMenus;
                } else {
                    this.menuCategories.basic = this.getDefaultBasicMenus();
                }
                resolve();
            }).catch(() => {
                // 文件不存在，使用默认配置
                this.menuCategories.basic = this.getDefaultBasicMenus();
                resolve();
            });
        });
    },

    /**
     * 获取默认basic菜单列表
     */
    getDefaultBasicMenus: function() {
        return [
            'status/overview',
	    'status/realtime',
            'netwizard',
            'system/system',
	    'system/admin',
            'system/ttyd',
            'system/advancedplus',
            'system/ota',
            'system/kucat-config',
	    'services/AdGuardHome',
            'control/eqosplus',
            'control/timecontrol',
            'control/watchdog',
            'control/taskplan',
            'network/firewall',
            'network/netspeedtest',
            'system/partexp'
        ];
    },

    /**
     * Load saved category from localStorage
     */
    loadSavedCategory: function() {
        try {
            const savedCategory = localStorage.getItem('luci-menu-category');
            if (savedCategory === 'basic' || savedCategory === 'allmenu') {
                this.currentCategory = savedCategory;
            }
        } catch (e) {
            console.debug('Load category error:', e);
        }
    },

    /**
     * Render the complete interface
     */
    render: function(tree) {
        try {
            var node = tree,
                url = '';

            // Render mode menu (top level)
            this.renderModeMenu(tree);

            // 先隐藏所有菜单项，避免闪现
            this.hideAllMenus();

            // Render tab menu for deep navigation
            if (L.env.dispatchpath.length >= 3) {
                for (var i = 0; i < 3 && node; i++) {
                    node = node.children[L.env.dispatchpath[i]];
                    url = url + (url ? '/' : '') + L.env.dispatchpath[i];
                }

                if (node) {
                    this.renderTabMenu(node, url);
                }
            }

            // Initialize sidebar functionality
            this.initSidebar();

            // Hide loading indicator
            this.hideLoading();

            // Initialize responsive behavior
            this.initResponsive();

            // 添加切换按钮
            setTimeout(() => {
                try {
                    this.addCategorySwitchButton();
                } catch (e) {
                    console.debug('Add category button error:', e);
                }
            }, 100);

            this.menuRendered = true;

            // 应用分类过滤
            setTimeout(() => {
                try {
                    this.applyCategoryFilter(this.currentCategory);
                } catch (e) {
                    console.debug('Apply category filter error:', e);
                }
            }, 150);
            
        } catch (e) {
            console.debug('Render error:', e);
        }
    },

    /**
     * 隐藏所有菜单项，避免闪现
     */
    hideAllMenus: function() {
        try {
            const existingStyle = document.getElementById('menu-hide-style');
            if (existingStyle) {
                existingStyle.remove();
            }
            
            const style = document.createElement('style');
            style.id = 'menu-hide-style';
            style.textContent = '#mainmenu .nav > li { display: none !important; }';
            document.head.appendChild(style);
        } catch (e) {
            console.debug('Hide menus error:', e);
        }
    },

    /**
     * 显示菜单项
     */
    showMenus: function() {
        try {
            const hideStyle = document.getElementById('menu-hide-style');
            if (hideStyle) {
                hideStyle.remove();
            }
        } catch (e) {
            console.debug('Show menus error:', e);
        }
    },

    /**
     * 添加分类切换按钮
     */
    addCategorySwitchButton: function() {
        try {
            const logoutContainer = document.querySelector('.logout-container') || 
                                   document.querySelector('.pull-right') ||
                                   document.querySelector('header .right') ||
                                   document.querySelector('.main-right .pull-right');
            
            if (logoutContainer) {
                this.insertSwitchButton(logoutContainer);
            }
        } catch (e) {
            console.debug('Add category button error:', e);
        }
    },

    /**
     * 插入切换按钮到指定容器
     */
    insertSwitchButton: function(container) {
        if (!container) return;
        
        try {
            if (container.querySelector('.category-switch')) {
                return;
            }

            const switchBtn = E('a', {
                'href': '#',
                'class': 'category-switch',
                'title': this.currentCategory === 'basic' ? _('Switch to Full Menus') : _('Switch to Custom Menus')
            }, [
                E('span', { 
                    'class': 'switch-icon ' + (this.currentCategory === 'basic' ? 'icon-allmenu' : 'icon-basic')
                })
            ]);

            switchBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.toggleCategory();
            });

            const logoutBtn = container.querySelector('a[href*="logout"], a[href*="sysauth"]');
            
            if (logoutBtn) {
                container.insertBefore(switchBtn, logoutBtn);
            } else {
                container.appendChild(switchBtn);
            }
        } catch (e) {
            console.debug('Insert button error:', e);
        }
    },

    /**
     * 切换分类
     */
    toggleCategory: function() {
        try {
            const newCategory = this.currentCategory === 'basic' ? 'allmenu' : 'basic';
            this.switchCategory(newCategory);
            
            const switchBtn = document.querySelector('.category-switch');
            if (switchBtn) {
                const iconSpan = switchBtn.querySelector('.switch-icon');
                const textSpan = switchBtn.querySelector('.switch-text');
                
                if (iconSpan) {
                    iconSpan.className = 'switch-icon ' + (newCategory === 'basic' ? 'icon-allmenu' : 'icon-basic');
                }
                
                switchBtn.title = newCategory === 'basic' ? _('Switch to Full Menus') : _('Switch to Custom Menus');
            }
        } catch (e) {
            console.debug('Toggle category error:', e);
        }
    },

    /**
     * Switch between Basic and allmenu categories
     */
    switchCategory: function(category) {
        if (category === this.currentCategory) return;
        
        try {
            this.currentCategory = category;
            localStorage.setItem('luci-menu-category', category);
            
            this.applyCategoryFilter(category);
        } catch (e) {
            console.debug('Switch category error:', e);
        }
    },

    /**
     * 判断是否为basic菜单
     */
    isBasicMenu: function(menuPath) {
        try {
            if (!menuPath || !this.menuCategories || !this.menuCategories.basic) return false;
            
            // 检查完整路径是否在basic列表中
            return this.menuCategories.basic.some(basicPath => {
                return basicPath === menuPath;
            });
        } catch (e) {
            return false;
        }
    },

    /**
     * Apply category filter to menu items
     */
    applyCategoryFilter: function(category) {
        try {
            this.showMenus();


            // 收集所有菜单项的路径信息
            const allMenuItems = document.querySelectorAll('#mainmenu .nav > li, #mainmenu .slide-menu li');
            const menuPaths = new Map();
            
            allMenuItems.forEach(item => {
                try {
                    const link = item.querySelector('a');
                    if (!link) return;
                    
                    const href = link.getAttribute('href');
                    if (!href) return;
                    
                    // 从href提取路径
                    const pathMatch = href.match(/\/admin\/(.+)/);
                    if (pathMatch) {
                        const fullPath = pathMatch[1];
                        menuPaths.set(item, fullPath);
                    }
                } catch (e) {}
            });

            if (category === 'basic') {
                // Basic模式：只显示basic列表中的菜单
                allMenuItems.forEach(item => {
                    try {
                        const fullPath = menuPaths.get(item);
                        if (!fullPath) {
                            item.style.display = 'none';
                            return;
                        }
                        
                        const isBasic = this.isBasicMenu(fullPath);
                        item.style.display = isBasic ? 'block' : 'none';
                        
                    } catch (e) {}
                });

                // 确保父菜单在子菜单可见时也显示
                this.ensureParentMenusVisible();
                
            } else {
                // allmenu模式：显示所有菜单
                allMenuItems.forEach(item => {
                    item.style.display = 'block';
                });
            }

            // 确保当前页面对应的菜单项可见并展开
            this.ensureCurrentMenuVisible();
            
        } catch (e) {
            console.debug('Apply category filter error:', e);
        }
    },

    /**
     * 确保父菜单在子菜单可见时也显示
     */
    ensureParentMenusVisible: function() {
        try {
            const slideMenus = document.querySelectorAll('#mainmenu .slide-menu');
            
            slideMenus.forEach(slideMenu => {
                // 检查这个下拉菜单是否有任何可见的子项
                const hasVisibleChildren = Array.from(slideMenu.children).some(child => 
                    child.style.display !== 'none'
                );
                
                if (hasVisibleChildren) {
                    // 如果有可见的子项，确保父菜单可见
                    const parentLi = slideMenu.closest('li.slide');
                    if (parentLi) {
                        parentLi.style.display = 'block';
                    }
                }
            });
        } catch (e) {
            console.debug('Ensure parent menus visible error:', e);
        }
    },

    /**
     * 确保当前页面对应的菜单项可见
     */
    ensureCurrentMenuVisible: function() {
        try {
            const currentPath = window.location.pathname;
            const menuItems = document.querySelectorAll('#mainmenu .nav > li, #mainmenu .slide-menu li');
            
            menuItems.forEach(item => {
                const link = item.querySelector('a');
                if (!link) return;
                
                const href = link.getAttribute('href');
                if (href && currentPath.includes(href)) {
                    // 确保当前菜单可见
                    item.style.display = 'block';
                    
                    // 如果是子菜单，确保所有父菜单也可见
                    let parent = item.parentElement?.closest('li.slide');
                    while (parent) {
                        parent.style.display = 'block';
                        parent = parent.parentElement?.closest('li.slide');
                    }
                    
                    // 如果是下拉菜单，展开它
                    if (item.classList.contains('slide')) {
                        item.classList.add('active');
                        const slideMenu = item.querySelector('.slide-menu');
                        if (slideMenu) {
                            slideMenu.style.display = 'block';
                        }
                    }
                }
            });
        } catch (e) {
            console.debug('Ensure menu visible error:', e);
        }
    },

    /**
     * Extract menu name from link
     */
    extractMenuName: function(link) {
        try {
            const href = link.getAttribute('href');
            if (!href) return '';
            
            const matches = href.match(/\/([^\/]+)$/);
            return matches ? matches[1] : '';
        } catch (e) {
            return '';
        }
    },

    /**
     * Get menu icon
     */
    getMenuIcon: function(menuName) {
        return this.menuIcons[menuName] || this.defaultIcon;
    },

    /**
     * Generate menu icon class
     */
    generateMenuIconClass: function(menuName) {
        const iconName = this.getMenuIcon(menuName);
        return `menu-icon-${iconName}`;
    },

    /**
     * Initialize sidebar toggle functionality
     */
    initSidebar: function() {
        try {
            var showSide = document.querySelector('.showSide');
            var darkMask = document.querySelector('.darkMask');
            var mainRight = document.querySelector('.main-right');
            
            if (showSide) {
                showSide.addEventListener('click', L.bind(this.toggleSidebar, this));
            }
            
            if (darkMask) {
                darkMask.addEventListener('click', L.bind(this.toggleSidebar, this));
            }
            
            if (mainRight) {
                mainRight.addEventListener('click', L.bind(this.handleMainClick, this));
            }
        } catch (e) {
            console.debug('Init sidebar error:', e);
        }
    },

    /**
     * Initialize responsive behavior
     */
    initResponsive: function() {
        try {
            if (window.innerWidth <= 920) {
                this.closeSidebar();
            }

            let resizeTimeout;
            window.addEventListener('resize', L.bind(function() {
                clearTimeout(resizeTimeout);
                resizeTimeout = setTimeout(() => {
                    try {
                        this.handleResize();
                    } catch (e) {
                        console.debug('Resize handler error:', e);
                    }
                }, 100);
            }, this));
        } catch (e) {
            console.debug('Init responsive error:', e);
        }
    },

    /**
     * Handle window resize events
     */
    handleResize: function() {
        try {
            var width = window.innerWidth;
            var mainLeft = document.querySelector('.main-left');
            var darkMask = document.querySelector('.darkMask');
            var switchBtn = document.querySelector('.category-switch');

            if (width > 920) {
                if (mainLeft) {
                    mainLeft.style.width = '';
                    mainLeft.style.visibility = 'visible';
                }
                if (darkMask) {
                    darkMask.style.visibility = 'hidden';
                    darkMask.style.opacity = '0';
                }
                if (switchBtn) {
                    switchBtn.style.display = 'inline-flex';
                }
                this.applyCategoryFilter(this.currentCategory);
            } else {
                this.closeSidebar();

            }
        } catch (e) {
            console.debug('Handle resize error:', e);
        }
    },

    /**
     * Toggle sidebar visibility (mobile)
     */
    toggleSidebar: function() {
        try {
            var mainLeft = document.querySelector('.main-left');
            var darkMask = document.querySelector('.darkMask');
            var mainRight = document.querySelector('.main-right');

            if (!mainLeft || !darkMask) return;

            var isOpen = mainLeft.style.width !== '0px' && mainLeft.style.width !== '0';

            if (isOpen) {
                this.closeSidebar();
            } else {
                this.openSidebar();
            }
        } catch (e) {
            console.debug('Toggle sidebar error:', e);
        }
    },

    handleMainClick: function(ev) {
        try {
            if (window.innerWidth <= 920 && document.body.classList.contains('sidebar-open')) {
                if (!ev.target.closest('.showSide')) {
                    this.closeSidebar();
                    ev.stopPropagation();
                }
            }
        } catch (e) {
            console.debug('Main click error:', e);
        }
    },

    openSidebar: function() {
        try {
            var mainLeft = document.querySelector('.main-left');
            var darkMask = document.querySelector('.darkMask');
            var mainRight = document.querySelector('.main-right');

            if (mainLeft) {
                mainLeft.style.width = '15rem';
                mainLeft.style.visibility = 'visible';
            }
            if (darkMask) {
                darkMask.style.visibility = 'visible';
                darkMask.style.opacity = '1';
            }
            if (mainRight) {
                mainRight.style.overflowY = 'hidden';
            }

            document.body.classList.add('sidebar-open');
        } catch (e) {
            console.debug('Open sidebar error:', e);
        }
    },

    closeSidebar: function() {
        try {
            var mainLeft = document.querySelector('.main-left');
            var darkMask = document.querySelector('.darkMask');
            var mainRight = document.querySelector('.main-right');

            if (mainLeft) {
                mainLeft.style.width = '0';
                mainLeft.style.visibility = 'hidden';
            }
            if (darkMask) {
                darkMask.style.visibility = 'hidden';
                darkMask.style.opacity = '0';
            }
            if (mainRight) {
                mainRight.style.overflowY = 'auto';
            }

            document.body.classList.remove('sidebar-open');
        } catch (e) {
            console.debug('Close sidebar error:', e);
        }
    },

    hideLoading: function() {
        try {
            var loading = document.querySelector('.main > .loading');
            if (loading) {
                loading.style.opacity = '0';
                loading.style.visibility = 'hidden';
                
                setTimeout(() => {
                    if (loading && loading.parentNode) {
                        loading.parentNode.removeChild(loading);
                    }
                }, 300);
            }
        } catch (e) {
            console.debug('Hide loading error:', e);
        }
    },

    handleMenuExpand: function(ev) {
        try {
            var target = ev.target;
            var slideItem = target.parentNode;
            var slideMenu = target.nextElementSibling;

            ev.preventDefault();
            ev.stopPropagation();

            if (!slideMenu || !slideMenu.classList.contains('slide-menu')) {
                return;
            }

            var isActive = slideItem.classList.contains('active');
            var allSlideItems = document.querySelectorAll('.main .main-left .nav > li.slide');

            allSlideItems.forEach(function(item) {
                if (item !== slideItem) {
                    var otherMenu = item.querySelector('.slide-menu');
                    if (otherMenu && otherMenu.style.display !== 'none') {
                        item.classList.remove('active');
                        item.querySelector('a.menu').classList.remove('active');
                        KucatAnimations.slideUp(otherMenu, 'fast');
                    }
                }
            });

            if (isActive) {
                slideItem.classList.remove('active');
                target.classList.remove('active');
                KucatAnimations.slideUp(slideMenu, 'fast');
            } else {
                slideItem.classList.add('active');
                target.classList.add('active');
                KucatAnimations.slideDown(slideMenu, 'fast');
            }

            target.blur();
        } catch (e) {
            console.debug('Menu expand error:', e);
        }
    },

    /**
     * Render main menu with category support
     */
    renderMainMenu: function(tree, url, level) {
        try {
            var currentLevel = (level || 0) + 1;
            var ul = E('ul', { 'class': level ? 'slide-menu' : 'nav' });
            var children = ui.menu.getChildren(tree);

            if (children.length === 0 || currentLevel > 2) {
                return E([]);
            }

            for (var i = 0; i < children.length; i++) {
                var child = children[i];
                var isActive = this.isMenuItemActive(child, tree, currentLevel);
                var submenu = this.renderMainMenu(child, url + '/' + child.name, currentLevel);
                var hasChildren = submenu.children.length > 0;
                
                var slideClass = hasChildren ? 'slide' : '';
                var menuClass = hasChildren ? 'menu' : '';
                
                if (isActive) {
                    slideClass += ' active';
                    menuClass += ' active';
                    ul.classList.add('active');
                }

                if (currentLevel === 1) {
                    const iconClass = this.generateMenuIconClass(child.name);
                    menuClass += ' ' + iconClass;
                }

                var menuItem = E('li', { 
                    'class': slideClass.trim()
                }, [
                    E('a', {
                        'href': L.url(url, child.name),
                        'click': (currentLevel === 1 && hasChildren) ? 
                                 ui.createHandlerFn(this, 'handleMenuExpand') : null,
                        'class': menuClass.trim(),
                        'data-title': child.title.replace(/ /g, '_'),
                    }, [_(child.title)]),
                    submenu
                ]);

                ul.appendChild(menuItem);
            }

            if (currentLevel === 1) {
                var container = document.querySelector('#mainmenu');
                if (container) {
                    container.appendChild(ul);
                    container.style.display = '';
                }
            }

            return ul;
        } catch (e) {
            console.debug('Render main menu error:', e);
            return E([]);
        }
    },

    isMenuItemActive: function(child, parent, level) {
        try {
            return (L.env.dispatchpath[level] === child.name) && 
                   (L.env.dispatchpath[level - 1] === parent.name);
        } catch (e) {
            return false;
        }
    },

    renderModeMenu: function(tree) {
        try {
            var ul = document.querySelector('#modemenu');
            var children = ui.menu.getChildren(tree);

            if (!ul) return;

            for (var i = 0; i < children.length; i++) {
                var isActive = (L.env.requestpath.length ? 
                    children[i].name == L.env.requestpath[0] : i == 0);

                ul.appendChild(E('li', {}, [
                    E('a', {
                        'href': L.url(children[i].name),
                        'class': isActive ? 'active' : null
                    }, [_(children[i].title)])
                ]));

                if (isActive) {
                    this.renderMainMenu(children[i], children[i].name);
                }

                if (i > 0 && i < children.length - 1) {
                    ul.appendChild(E('li', {'class': 'divider'}, [E('span')]));
                }
            }

            if (children.length > 1) {
                ul.parentElement.style.display = '';
            }
        } catch (e) {
            console.debug('Render mode menu error:', e);
        }
    },

    renderTabMenu: function(tree, url, level) {
        try {
            var container = document.querySelector('#tabmenu');
            var currentLevel = (level || 0) + 1;
            var ul = E('ul', { 'class': 'tabs' });
            var children = ui.menu.getChildren(tree);
            var activeNode = null;

            if (children.length === 0 || !container) {
                return E([]);
            }

            for (var i = 0; i < children.length; i++) {
                var child = children[i];
                var isActive = (L.env.dispatchpath[currentLevel + 2] === child.name);
                var activeClass = isActive ? ' active' : '';
                var className = 'tabmenu-item-%s %s'.format(child.name, activeClass);

                ul.appendChild(E('li', { 
                    'class': className.trim()
                }, [
                    E('a', { 
                        'href': L.url(url, child.name) 
                    }, [_(child.title)])
                ]));

                if (isActive) {
                    activeNode = child;
                }
            }

            container.appendChild(ul);
            container.style.display = '';

            if (activeNode) {
                container.appendChild(this.renderTabMenu(
                    activeNode, 
                    url + '/' + activeNode.name, 
                    currentLevel
                ));
            }

            return ul;
        } catch (e) {
            console.debug('Render tab menu error:', e);
            return E([]);
        }
    }
});