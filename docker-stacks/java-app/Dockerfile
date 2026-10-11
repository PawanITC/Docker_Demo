# Multi-stage build: compile with the full JDK, run on the much smaller JRE.

# ---- Stage 1: build ----
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY App.java .
RUN javac App.java && jar --create --file app.jar --main-class App *.class

# ---- Stage 2: runtime ----
FROM eclipse-temurin:21-jre-alpine

ENV DATA_DIR=/data
WORKDIR /app
COPY --from=build /src/app.jar .

# Non-root user that owns the data directory (see python-app for why this
# happens before VOLUME).
RUN addgroup -S app && adduser -S -G app -u 1000 app \
 && mkdir -p /data && chown app:app /data
USER app

VOLUME /data

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["java", "-jar", "app.jar"]
