#!/usr/bin/env python3
"""
RoamQuest Skills - Helper scripts for efficient development
"""

import os
import sys
import subprocess
import json
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
SKILLS_FILE = PROJECT_ROOT / ".claude" / "skills.json"


def load_skills():
    """Load skills configuration"""
    with open(SKILLS_FILE, 'r') as f:
        return json.load(f)


def run_command(cmd: list, description: str = ""):
    """Run a command and return result"""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300
        )
        if result.returncode == 0:
            print(f"✓ {description}" if description else "✓ Success")
            if result.stdout.strip():
                print(result.stdout.strip())
        else:
            print(f"✗ {description}" if description else "✗ Failed")
            if result.stderr.strip():
                print(f"  Error: {result.stderr}")
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print(f"✗ Timeout: {description}" if description else "✗ Timeout")
        return False
    except Exception as e:
        print(f"✗ Exception: {e}")
        return False


# ==================== Flutter Commands ====================

def run_app():
    """Launch iOS simulator and run RoamQuest app in debug mode"""
    # Boot simulator
    subprocess.run([
        'xcrun', 'simctl', 'boot',
        '04EECB16-13C4-42E0-8E95-452982683A5A'
    ], capture_output=True)

    # Wait for simulator to boot
    import time
    time.sleep(3)

    # Run flutter
    os.chdir(PROJECT_ROOT)
    subprocess.run([
        'flutter', 'run',
        '-d', '04EECB16-13C4-42E0-8E95-452982683A5A'
    ])


def hot_reload():
    """Trigger hot reload on a running Flutter app"""
    print("Hot reload: Press 'r' in Flutter run terminal")
    print("Or use: /roamquest.reload")


def hot_restart():
    """Trigger hot restart on a running Flutter app"""
    print("Hot restart: Press 'R' in Flutter run terminal")
    print("Or use: /roamquest.restart")


def build_ios():
    """Build iOS app"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'clean'])
    subprocess.run(['flutter', 'build', 'ios', '--debug'])


def run_tests():
    """Run Flutter tests"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'test'])


def analyze_code():
    """Run Flutter analyze"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'analyze'])


def format_code():
    """Format Dart code"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['dart', 'format', '.'])


def fix_code():
    """Auto-fix code issues"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['dart', 'fix', '--apply'])


def flutter_doctor():
    """Run Flutter doctor"""
    subprocess.run(['flutter', 'doctor', '-v'])


def clean_cache():
    """Clean Flutter build cache"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'clean'])


def install_deps():
    """Install Flutter dependencies"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'pub', 'get'])


def upgrade_deps():
    """Upgrade Flutter dependencies"""
    os.chdir(PROJECT_ROOT)
    subprocess.run(['flutter', 'pub', 'upgrade'])


# ==================== Location Debug Commands ====================

def toggle_location_debug(enable: bool):
    """Toggle location debug mode (mock data vs real GPS)"""
    # Open home_page.dart
    home_page_file = PROJECT_ROOT / "lib/features/home/home_page.dart"

    # Read the file content
    if home_page_file.exists():
        with open(home_page_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if _debugMode is already defined
        if '_debugMode' in content:
            # Toggle the value
            if '_debugMode = true;' in content:
                new_content = content.replace('_debugMode = true;', '_debugMode = false;')
            else:
                new_content = content.replace('_debugMode = false;', '_debugMode = true;')

            # Write back
            with open(home_page_file, 'w', encoding='utf-8') as f:
                f.write(new_content)

            if enable:
                print("✓ Location debug mode: ENABLED (Using mock data)")
            else:
                print("✓ Location debug mode: DISABLED (Using real GPS)")
    else:
        print(f"✗ Could not find _debugMode setting in {home_page_file}")


# ==================== Navigation Commands ====================

def open_file(file_path: str = "lib/main.dart"):
    """Open a file in default editor"""
    full_path = PROJECT_ROOT / file_path
    if full_path.exists():
        subprocess.run(['code', str(full_path)])
        print(f"✓ Opened: {file_path}")
    else:
        print(f"✗ File not found: {file_path}")


def find_files(pattern: str = "*.dart", path: str = "lib/"):
    """Find files matching a pattern"""
    search_path = PROJECT_ROOT / path

    if '*' in pattern or '?' in pattern:
        # Use glob for patterns
        files = list(search_path.glob(pattern))
    else:
        # Simple find
        files = list(search_path.glob(pattern))

    print(f"Found {len(files)} files matching '{pattern}' in '{path}':")
    for f in files[:20]:  # Show first 20 results
        print(f"  - {f.relative_to(PROJECT_ROOT)}")
    if len(files) > 20:
        print(f"  ... and {len(files) - 20} more")

    return files


def grep_code(pattern: str, path: str = "lib/"):
    """Search for pattern in code files"""
    search_path = PROJECT_ROOT / path
    matches = []

    for file_path in search_path.rglob("*.dart"):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1, None):
                    if re.search(pattern, line):
                        matches.append((file_path.relative_to(PROJECT_ROOT), line_num, line.strip()))
                        break  # Only show first match per file
        except:
            pass

    print(f"Found {len(matches)} matches for '{pattern}' in '{path}':")
    for file_path, line_num, line in matches[:10]:
        print(f"  {file_path}:{line_num}: {line[:80]}")
    if len(matches) > 10:
        print(f"  ... and {len(matches) - 10} more")

    return matches


def show_structure():
    """Display project structure"""
    try:
        result = subprocess.run(
            ['tree', '-L', '-3', 'lib/'],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            print(result.stdout)
        else:
            # Fallback to find
            find_lib()
    except FileNotFoundError:
        # Fallback to find
        find_lib()


def find_lib():
    """Fallback: show lib structure using find"""
    result = subprocess.run(
        ['find', 'lib/', '-type', 'd', '-maxdepth', '2'],
        capture_output=True,
        text=True
    )
    print(result.stdout)


# ==================== Documentation Commands ====================

def open_docs():
    """Open documentation files"""
    docs_dir = PROJECT_ROOT / "docs"
    sql_dir = PROJECT_ROOT / "sql"

    print("Documentation files:")

    # Check for SQL files
    if sql_dir.exists():
        for f in sql_dir.glob("*.sql"):
            print(f"  SQL: {f.name}")

    # Check for README
    readme = PROJECT_ROOT / "README.md"
    if readme.exists():
        print(f"  - README.md")

    # Check for iOS progress doc
    ios_doc = PROJECT_ROOT / "docs" / "ios_app_store_progress.md"
    if ios_doc.exists():
        print(f"  - iOS App Store Progress")

    # Open README if exists
    if readme.exists():
        subprocess.run(['code', str(readme)])
        print(f"✓ Opened README.md")


# ==================== Main ====================

def main():
    if len(sys.argv) < 2:
        print("RoamQuest Skills - Helper for efficient development")
        print("\nUsage: python3 roamquest_skills.py <skill> [args]")
        print("\nFlutter Commands:")
        print("  /roamquest.run              - Run on iOS simulator")
        print("  /roamquest.hot_reload       - Hot reload app")
        print("  /roamquest.restart          - Hot restart app")
        print("  /roamquest.build_ios        - Build iOS app")
        print("  /roamquest.run_test        - Run tests")
        print("  /roamquest.analyze         - Analyze code")
        print("  /roamquest.format           - Format code")
        print("  /roamquest.fix             - Auto-fix code")
        print("  /roamquest.doctor          - Flutter doctor")
        print("  /roamquest.clean            - Clean cache")
        print("  /roamquest.install_deps    - Install dependencies")
        print("  /roamquest.upgrade_deps     - Upgrade dependencies")
        print("\nNavigation Commands:")
        print("  /roamquest.open_main       - Open main.dart")
        print("  /roamquest.open_home       - Open home page")
        print("  /roamquest.find_files      - Find files")
        print("  /roamquest.grep_code       - Search in code")
        print("  /roamquest.show_structure  - Show project structure")
        print("\nLocation Debug Commands:")
        print("  /roamquest.toggle_debug     - Toggle location debug mode (ENABLE=mock data)")
        print("\nDocumentation Commands:")
        print("  /roamquest.open_docs        - Open documentation")
        sys.exit(1)

    skill = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else []

    # Mapping skill names to functions
    skill_map = {
        # Flutter commands
        'roamquest.run': run_app,
        'roamquest.hot_reload': hot_reload,
        'roamquest.restart': hot_restart,
        'roamquest.build_ios': build_ios,
        'roamquest.run_test': run_tests,
        'roamquest.analyze': analyze_code,
        'roamquest.format': format_code,
        'roamquest.fix': fix_code,
        'roamquest.doctor': flutter_doctor,
        'roamquest.clean': clean_cache,
        'roamquest.install_deps': install_deps,
        'roamquest.upgrade_deps': upgrade_deps,

        # Navigation commands
        'roamquest.open_main': lambda: open_file() if not args else open_file(args[0]),
        'roamquest.open_home': lambda: open_file('lib/features/home/home_page.dart'),
        'roamquest.find_files': lambda: find_files(args[0] if args else '*.dart'),
        'roamquest.grep_code': lambda: grep_code(args[0] if args else 'TODO', path='lib/'),
        'roamquest.show_structure': show_structure,
        'roamquest.open_docs': open_docs,

        # Location debug commands
        'roamquest.toggle_debug': toggle_location_debug,
    }

    if skill in skill_map:
        skill_map[skill]()
    else:
        print(f"✗ Unknown skill: {skill}")
        print("\nAvailable skills:")
        for key in skill_map.keys():
            print(f"  {key}")


if __name__ == '__main__':
    main()
