"""Configuración de Django para FacturaFlow Mobile Cloud.

Los secretos y los datos de conexión se leen del entorno (archivo .env en
desarrollo, Secret Manager en Google Cloud). Nunca se escriben en el código.
"""

from pathlib import Path
import os

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")


def _env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def _env_bool(name: str, default: bool = False) -> bool:
    return _env(name, str(default)).strip().lower() in {"1", "true", "yes", "on"}


# --- Seguridad -------------------------------------------------------
# Sin valor por defecto en producción: si falta la variable, el arranque
# falla de forma evidente en vez de usar una clave conocida.
SECRET_KEY = _env("DJANGO_SECRET_KEY", "clave-solo-para-desarrollo-local")

DEBUG = _env_bool("DJANGO_DEBUG", False)

ALLOWED_HOSTS = [h.strip() for h in _env("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",") if h.strip()]

# Fuera de DEBUG se exige HTTPS extremo a extremo.
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.staticfiles",
    "rest_framework",
    "invoices",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
]

ROOT_URLCONF = "facturaflow.urls"
WSGI_APPLICATION = "facturaflow.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {"context_processors": []},
    }
]

# --- Base de datos ---------------------------------------------------
# PostgreSQL 17, en local sobre contenedor y en producción sobre
# Google Cloud SQL. El esquema `facturaflow` se fija en search_path para
# que el ORM no dependa de `public`.
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": _env("DB_NAME", "facturaflow"),
        "USER": _env("DB_USER", "postgres"),
        "PASSWORD": _env("DB_PASSWORD"),
        "HOST": _env("DB_HOST", "127.0.0.1"),
        "PORT": _env("DB_PORT", "5432"),
        "CONN_MAX_AGE": 600,
        "OPTIONS": {
            "sslmode": _env("DB_SSLMODE", "prefer"),
            "options": "-c search_path=facturaflow,public",
        },
    }
}

# El certificado raíz solo se envía cuando se exige verificación completa.
if _env("DB_SSLROOTCERT"):
    DATABASES["default"]["OPTIONS"]["sslrootcert"] = _env("DB_SSLROOTCERT")

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LANGUAGE_CODE = "es-co"
TIME_ZONE = "America/Bogota"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
}
