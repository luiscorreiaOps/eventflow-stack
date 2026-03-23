import pytest


def test_requirements_file_exists():
    import os
    assert os.path.exists("requirements.txt")


def test_producer_app_exists():
    import os
    assert os.path.exists("app/producer/app.py")


def test_worker_app_exists():
    import os
    assert os.path.exists("app/worker/app.py")


def test_autoscale_exists():
    import os
    assert os.path.exists("swarm/autoscale.py")


def test_producer_dockerfile_exists():
    import os
    assert os.path.exists("app/producer/Dockerfile")


def test_worker_dockerfile_exists():
    import os
    assert os.path.exists("app/worker/Dockerfile")


def test_producer_env_exists():
    import os
    assert os.path.exists("app/producer/.env")


def test_worker_env_exists():
    import os
    assert os.path.exists("app/worker/.env")
