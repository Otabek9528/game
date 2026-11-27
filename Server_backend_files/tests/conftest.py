"""
Tests for the server modules in Server_backend_files.

    cd Server_backend_files && python -m pytest tests -q

Needs flask, requests and pytest. app_accounts is replaced by a stand-in
that only records the hooks, so no accounts database is needed.
"""
import os
import sys
import types

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

if 'app_accounts' not in sys.modules:
    stub = types.ModuleType('app_accounts')
    stub.movers, stub.deleters = [], []
    stub.on_user_moved = lambda fn: stub.movers.append(fn) or fn
    stub.on_user_deleted = lambda fn: stub.deleters.append(fn) or fn
    sys.modules['app_accounts'] = stub
