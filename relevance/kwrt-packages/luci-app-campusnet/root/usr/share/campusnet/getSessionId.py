#Simulate sign-in to get Cookie
#Cookie expiration time is 30 minutes

import socket
import requests

def get_router_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('223.5.5.5', 53))
        ip = s.getsockname()[0]
    finally:
        s.close()
    
    return ip

def get_base_ip():
    base_ip = ""
    try:
        with open("/etc/config/campusnet", 'r') as f:
            lines = f.readlines()
            for line in lines:
                items = line.split()
                if len(items) < 3:
                    continue
                if items[1] == "base_ip":
                    base_ip = items[2][1:-1]
                    break
    except Exception as e:
        print(e)
        return ""
    return base_ip


routerIP = get_router_ip()
login_url = "http://139.198.3.98/sdjd/protalAction!index.action?wlanuserip="+routerIP+"&basip="+get_base_ip()
res = requests.get(login_url)
cookies_org = res.cookies
cookies = requests.utils.dict_from_cookiejar(cookies_org)
if 'JSESSIONID' in cookies:
    print(cookies["JSESSIONID"])
if 'route' in cookies:
    print(cookies["route"])
print(routerIP)
