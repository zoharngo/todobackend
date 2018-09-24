from setuptools import setup, find_packages

setup(
    name                 = "todobackend",
    version              = "0.1.0",
    description          = "TodoBackend Djnago REST service",
    packages              = find_packages(),
    include_package_data = True,
    scripts              = ["manage.py"],
    install_requires     = ["Django>=1.9,<2.0",
                            "django-cors-headers>=2.4.0",
                            "djangorestframework>=3.8.2",
                            "MySQL-python>=1.2.5",
                            "uwsgi>=2.0"
                            ],
    extras_require     =   {
                                "test": [
                                    "colorama>=0.3.9",
                                    "coverage>=4.5.1",
                                    "django-nose>=1.4.5",
                                    "nose>=1.3.7",
                                    "pinocchio>=0.4.2"
                                ]
                            }
)