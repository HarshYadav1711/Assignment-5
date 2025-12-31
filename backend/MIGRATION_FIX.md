# Migration Fix Instructions

If you encounter "Dependency on app with no migrations" errors, run:

```bash
# Inside Docker container
docker-compose exec web python manage.py makemigrations

# Then apply migrations
docker-compose exec web python manage.py migrate
```

This will generate proper migrations for all apps based on the current model definitions.

