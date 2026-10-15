# ============================================================
# Dockerfile - Multi-stage Build cho Spring Boot
# ============================================================

# ---- Stage 1: Builder ----
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

RUN chmod +x gradlew

# Cache dependencies layer riêng
RUN ./gradlew dependencies --no-daemon || true

COPY src src

# Build JAR (skip test vì CI đã chạy riêng)
RUN ./gradlew bootJar --no-daemon -x test

# ---- Stage 2: Runtime ----
FROM eclipse-temurin:21-jre-alpine AS runtime

LABEL org.opencontainers.image.title="Spring VPS App"
LABEL org.opencontainers.image.description="Spring Boot app auto-deployed to VPS via SSH"

# Non-root user để tăng bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /workspace/build/libs/*.jar app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
