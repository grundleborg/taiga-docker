#! /bin/bash

##########################################
# Set up postgres data directory
echo "Setting up postgres data directory."
sudo mkdir -p /data/postgresql

##########################################
# Set up postgres docker container
echo "Creating postgres docker container."
sudo docker run -d --name postgres -e POSTGRES_PASSWORD="$1" -p 5432:5432  -v /data/postgresql:/var/lib/postgresql/data postgres
sudo docker stop postgres

#########################################
# Configure postgres container
echo "Configuring postgres container."
sudo sed -ri "s/host all \"postgres\" 0.0.0.0\/0 md5/host all all 0.0.0.0\/0 md5/" /data/postgresql/pg_hba.conf
sudo docker start postgres
sudo docker run -it --link postgres:postgres --rm postgres sh -c "su postgres --command 'PGPASSWORD=\"$1\" createuser -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -d -r -s taiga'"
sudo docker run -it --link postgres:postgres --rm postgres sh -c "su postgres --command 'PGPASSWORD=\"$1\" createdb -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -O taiga taiga'";
sudo docker run -it --link postgres:postgres --rm postgres sh -c "su postgres --command 'PGPASSWORD=\"$1\" psql -c \"ALTER USER taiga WITH PASSWORD '\''$2'\'';\" -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" taiga'";

#########################################
# Set up the backend container
echo "Setting up the backend container."
sudo mkdir -p /data/taiga/settings
sudo cp backend/local.py /data/taiga/settings
sudo docker run -it --rm -p 8000:8000 --link postgres:postgres -e "PGPASSWORD=$2" -v /data/nginx/html/static:/taiga/static -v /data/taiga/settings:/mnt/settings taiga-back sh -c "cp /mnt/settings/local.py /taiga/settings/local.py && python manage.py collectstatic --noinput"
sudo docker run -d --name taiga-back -p 8000:8000 --link postgres:postgres -e "PGPASSWORD=$2" -v /data/nginx/html/static:/taiga/static -v /data/taiga/settings:/mnt/settings taiga-back

#########################################
# Set up the frontend container
echo "Setting up the frontend container."
sudo docker run -it --rm -v /data/nginx/html:/usr/share/nginx/html taiga-front cp -r /taiga/dist/. /usr/share/nginx/html
sudo mkdir -p /data/nginx/conf.d
sudo cp frontend/taiga.conf /data/nginx/conf.d/default.conf
sudo docker run -d --name taiga-front -p 80:80 -v /data/nginx/html:/usr/share/nginx/html -v /data/nginx/conf.d:/etc/nginx/conf.d --link taiga-back:taiga-back taiga-front

#########################################
# Generate the database
sudo docker run -it --rm --link postgres:postgres -e "PGPASSWORD=$2" -v /data/taiga/settings:/mnt/settings taiga-back sh -c "cp /mnt/settings/local.py /taiga/settings/local.py && bash regenerate.sh"

#########################################
# Stop all containers.
echo "Stopping created docker containers."
sudo docker stop taiga-front
sudo docker stop taiga-back
sudo docker stop postgres

echo "Done."
