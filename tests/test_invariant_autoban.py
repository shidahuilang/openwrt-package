import pytest
import subprocess
import sys
import os
import tempfile
import shutil


@pytest.mark.parametrize("ip_input", [
    "192.168.1.1",  # valid IP
    "10.0.0.1; rm -rf /",  # command injection attempt
    "127.0.0.1 && cat /etc/passwd",  # shell metacharacter injection
    "192.168.1.1`whoami`",  # command substitution attempt
    "256.256.256.256",  # invalid IP (boundary)
])
def test_autoban_command_injection_prevention(ip_input):
    """Invariant: iptables command execution must not allow shell metacharacter injection or arbitrary command execution"""
    
    # Create a temporary test script that imports and calls the vulnerable function
    test_script = f'''
import sys
sys.path.insert(0, "{os.path.dirname(os.path.abspath(__file__))}")

# Mock os.system to capture the command instead of executing it
import os
captured_cmd = None
original_system = os.system

def mock_system(cmd):
    global captured_cmd
    captured_cmd = cmd
    return 0

os.system = mock_system

# Import the actual module
sys.path.insert(0, "/root/usr/share/ssr_mudb_server/utils")
try:
    from autoban import ban_ip
    ban_ip("{ip_input}")
    print(f"COMMAND:{{captured_cmd}}")
except Exception as e:
    print(f"ERROR:{{e}}")
'''
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(test_script)
        f.flush()
        temp_file = f.name
    
    try:
        result = subprocess.run(
            [sys.executable, temp_file],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        output = result.stdout + result.stderr
        
        # Security invariant: the command must not contain unescaped shell metacharacters
        # that could allow injection (;, |, &, `, $(), etc.)
        dangerous_patterns = [';', '&&', '||', '`', '$(', '|']
        
        # Extract the command from output
        for line in output.split('\n'):
            if line.startswith('COMMAND:'):
                cmd = line.replace('COMMAND:', '').strip()
                # The IP should be properly isolated in the iptables command
                # Valid iptables commands should only contain the IP in the -s parameter
                for pattern in dangerous_patterns:
                    # If pattern appears outside of a properly quoted context, it's a vulnerability
                    if pattern in cmd and f"'{ip_input}" not in cmd and f'"{ip_input}' not in cmd:
                        # Check if the dangerous pattern is actually part of the injected payload
                        if pattern in ip_input:
                            pytest.fail(f"Shell injection detected: dangerous pattern '{pattern}' from input was not neutralized in command: {cmd}")
    finally:
        os.unlink(temp_file)