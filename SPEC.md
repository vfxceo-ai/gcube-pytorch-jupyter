# 작업 명세 — gcube 위에 PyTorch + JupyterLab 환경 배포

## 목표

GitHub repo `vfxceo-ai/gcube-pytorch-jupyter` 를 생성하고, PyTorch + JupyterLab Docker 이미지를 GitHub Actions 로 자동 빌드하여 ghcr.io 에 푸시한 뒤, gcube 워크로드로 배포한다.

## 결과물

### Dockerfile

- 베이스: `pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime`
- 추가 설치 패키지: `jupyterlab`, `numpy`, `pandas`, `matplotlib`, `transformers`, `datasets`
- 작업 디렉터리: `/workspace`
- 노출 포트: `8888`
- 자동 실행: JupyterLab (IP `0.0.0.0`, 토큰은 `JUPYTER_TOKEN` 환경변수가 있으면 그 값, 없으면 토큰 없이)

### GitHub repo

- 이름: `gcube-pytorch-jupyter`
- 소유자: `vfxceo-ai`
- 가시성: public 또는 private (사용자에게 질문)
- 초기 커밋: Dockerfile, GitHub Actions 워크플로우, README

### GitHub Actions 워크플로우

- 트리거: `main` 브랜치 push
- 작업: Docker 이미지 빌드 → `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter` 푸시
- 권한: `packages: write`

### gcube workload.yaml

- description: `gcube-pytorch-jupyter`
- containerImage: `vfxceo-ai/gcube-pytorch-jupyter:latest`
- repo: `ghcr.io`
- port: `8888`
- gpuCode: `099` (RTX3070 8GB Tier 3, `gcube gpu list` 기준 확인 필요)
- cuda: `""` (GCUBE 노드 선택 조건이므로 특별한 이유가 없으면 비움)
- sharedMemory: `4`

ghcr 이미지가 private 인 경우 gcube 에 GitHub 크레덴셜 등록 필요 — `gcube credential list` 로 확인 후 없으면 사용자에게 안내.

## 작업 흐름

1. Dockerfile 작성 (`./Dockerfile`)
2. GitHub Actions 워크플로우 작성 (`./.github/workflows/build.yml`)
3. README 작성 (`./README.md`)
4. GitHub repo 생성 및 초기 push
5. GitHub Actions 빌드 완료 확인 (ghcr 에 이미지 푸시 성공)
6. workload.yaml 작성 (`./workload.yaml`)
7. `gcube workload register -f workload.yaml` 실행 → SER 확보
8. `gcube workload start <ser>` 실행
9. 1~2분 대기 후 `gcube workload describe <ser>` 와 `gcube -o json workload pods <ser>` 로 배포 상태와 pod readiness 확인

## 검증

- GitHub Actions 빌드 성공 + ghcr 에 이미지 존재
- gcube workload describe 결과의 state 가 `deploy`
- `gcube -o json workload pods <ser>` 결과에서 pod 가 `Running` 이고 container 가 `ready: true`
- JupyterLab 서비스 URL 이 열리고 포트 `8888` 로 응답
- gcube console 에 SSH 접속 정보와 서비스 URL 표시 (사용자가 직접 확인)
