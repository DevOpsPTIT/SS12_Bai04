# Bài 4 - Session 12: Auto Deploy Spring Boot Container to VPS via SSH

## Mô tả

Workflow CI/CD 2 job nối tiếp nhau: **build Docker Image → SSH vào VPS → pull & restart Container**.

## Cấu trúc thư mục

```
SS12/Bai04/
├── .github/
│   └── workflows/
│       └── deploy-vps.yml                   ← ⭐ Workflow chính (file nộp bài)
├── src/
│   ├── main/java/com/example/springvpsapp/
│   │   ├── SpringVpsAppApplication.java
│   │   └── AppInfoController.java
│   └── main/resources/
│       ├── application.properties
│       └── application-prod.properties
├── Dockerfile                               ← Multi-stage build
├── build.gradle                             ← Có Actuator dependency
├── settings.gradle
├── .gitignore
└── README.md
```

## Thiết lập Repository Secrets (BẮT BUỘC)

```
GitHub Repo → Settings → Secrets and variables → Actions → New repository secret
```

| Secret Name | Giá trị |
|---|---|
| `SSH_HOST` | IP hoặc hostname của VPS (vd: `192.168.1.100`) |
| `SSH_USER` | Tên user SSH trên VPS (vd: `ubuntu`, `root`) |
| `SSH_KEY` | Toàn bộ nội dung Private Key SSH |

### Cách lấy SSH Private Key

```bash
# Tạo SSH key pair (nếu chưa có)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy

# Copy Public Key lên VPS
ssh-copy-id -i ~/.ssh/github_deploy.pub user@your-vps-ip

# Lấy nội dung Private Key để dán vào Secret SSH_KEY
cat ~/.ssh/github_deploy
# Copy toàn bộ nội dung từ -----BEGIN đến END----- vào Secret
```

## Workflow: [deploy-vps.yml](.github/workflows/deploy-vps.yml)

### Luồng 2 Job nối tiếp

```
push to main
     │
     ▼
┌──────────────────────────────────────┐
│  Job 1: build-image                  │
│                                      │
│  ✓ checkout                          │
│  ✓ login GHCR (GITHUB_TOKEN)         │
│  ✓ setup buildx                      │
│  ✓ extract metadata (tags: latest+sha)│
│  ✓ build & push → ghcr.io/..:latest  │
└─────────────────┬────────────────────┘
                  │  needs: build-image
                  ▼
┌──────────────────────────────────────┐
│  Job 2: deploy-vps                   │
│                                      │
│  appleboy/ssh-action@v1.0.3          │
│  ├─ SSH connect → VPS                │
│  ├─ docker login ghcr.io             │
│  ├─ docker pull ..:latest            │
│  ├─ docker stop spring-vps-app       │
│  ├─ docker rm   spring-vps-app       │
│  └─ docker run -d -p 8080:8080 ...   │
│       --restart unless-stopped       │
│       -e SPRING_PROFILES_ACTIVE=prod │
└──────────────────────────────────────┘
```

### Lệnh Docker trên VPS

```bash
# Pull image mới
docker pull ghcr.io/<owner>/spring-vps-app:latest

# Stop & remove container cũ
docker stop spring-vps-app || true
docker rm   spring-vps-app || true

# Chạy container mới
docker run -d \
  --name spring-vps-app \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  ghcr.io/<owner>/spring-vps-app:latest
```

## Kiểm tra sau khi deploy

```bash
# Health check qua Actuator
curl http://<VPS_IP>:8080/actuator/health
# → {"status":"UP",...}

# App info
curl http://<VPS_IP>:8080/
# → {"app":"spring-vps-app","profile":"prod",...}

# API endpoint
curl http://<VPS_IP>:8080/api/hello
# → {"message":"Hello from VPS! 🚀","profile":"prod"}
```

## Endpoints

| Endpoint | Mô tả |
|---|---|
| `GET /` | Thông tin ứng dụng (version, profile, host) |
| `GET /api/hello` | Hello message |
| `GET /actuator/health` | Health check — dùng để xác nhận deploy thành công |
| `GET /actuator/info` | App info từ Actuator |

## Yêu cầu trên VPS

- Docker đã được cài đặt
- Port 8080 đã được mở trong firewall
- User SSH có quyền chạy lệnh `docker`
