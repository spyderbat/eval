FROM peaceiris/mdbook:latest AS build

WORKDIR /code
COPY . .
RUN mdbook build

FROM lipanski/docker-static-website:latest

COPY --from=build /code/book .

