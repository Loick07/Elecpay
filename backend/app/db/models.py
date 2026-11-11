"""Registre de tous les modèles.

Alembic importe ce module pour que chaque table soit connue de `Base.metadata`
(sinon `--autogenerate` ne la verrait pas). Chaque nouveau module de modèles
doit être importé ici, par exemple :

    from app.modules.users import models as users_models  # noqa: F401

Aucune table pour l'instant : elles arrivent à l'étape B1.
"""

from app.db.base import Base

__all__ = ["Base"]
