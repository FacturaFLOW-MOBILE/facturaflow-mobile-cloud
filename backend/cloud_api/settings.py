"""Configuración independiente: no toca la configuración PostgreSQL del Taller 6."""
import os
from pathlib import Path
from dotenv import load_dotenv
from django.core.exceptions import ImproperlyConfigured

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env.firestore')
DEBUG = os.getenv('DJANGO_DEBUG', 'false').lower() == 'true'
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', '')
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = 'solo-desarrollo-cambiar-al-desplegar-no-es-seguro'
    else:
        raise ImproperlyConfigured('Se requiere DJANGO_SECRET_KEY en producción')
ALLOWED_HOSTS = [h.strip() for h in os.getenv('DJANGO_ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',') if h.strip()]
ROOT_URLCONF = 'cloud_api.urls'
INSTALLED_APPS = []
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
]
DATABASES = {}
USE_TZ = True
TIME_ZONE = 'America/Bogota'
DEFAULT_CHARSET = 'utf-8'
APPEND_SLASH = False
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True

FIRESTORE_PROJECT = os.getenv('FIRESTORE_PROJECT', 'facturaflow-mcc-2026')
MAX_ITEMS = 40
