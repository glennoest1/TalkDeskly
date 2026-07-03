# TalkDeskly

Modern, real-time chat application with embeddable components. Built for scalability and seamless integration.

TalkDeskly is a single-binary application built with Go and React.

![TalkDeskly Demo](docs/images/hero.png)

Visit [talkdeskly.com](https://talkdeskly.com) for more info. Check out the [**Live demo**](https://demo.talkdeskly.com/).

> **CAUTION:** This project is currently in **development**. Features and APIs may change and are not yet fully tested.

## Deploy And Run

Run deployment through the standalone Bash scripts. This is the supported entry point for every mode.

```bash
./scripts/deploy-local.sh start
./scripts/deploy-dev.sh start
./scripts/deploy-prod.sh start
```

Choose the mode from the deployment guide that matches what you need:

| Mode | Main command | Use when | Guide |
| --- | --- | --- | --- |
| Local host-run | `./scripts/deploy-local.sh start` | Backend, frontend, and chat widget run as host processes; dependency services run in Docker. | [Local deployment](docs/local/local-deployment.md) |
| Docker development | `./scripts/deploy-dev.sh start` | Backend, frontend, chat widget, Postgres, Redis, and MailHog all run in Docker for development. | [Development deployment](docs/dev/development-deployment.md) |
| Production-style | `./scripts/deploy-prod.sh start` | Frontend and widget assets are built into the backend image and run with production Compose. | [Production deployment](docs/prod/production-deployment.md) |

Common deploy commands:

```bash
./scripts/deploy-local.sh status
./scripts/deploy-dev.sh logs --tail 100
./scripts/deploy-dev.sh seed
./scripts/deploy-dev.sh restart
./scripts/deploy-dev.sh reset --service backend
./scripts/deploy-prod.sh build
```

## Deployment Documentation

Start with [docs/README.md](docs/README.md) if you are not sure which mode to use.

| Document | What it covers |
| --- | --- |
| [Deployment overview](docs/README.md) | Mode comparison, communication architecture, quick commands, and first-run paths. |
| [Deployment scripts](docs/deployment-scripts.md) | Direct script commands, script modules, supported options, E2E checks, and troubleshooting. |
| [Startup environment](docs/startup-environment.md) | Required startup environment variables and example files for local, dev, and prod. |
| [Local deployment](docs/local/local-deployment.md) | Host-run local setup and testing flow. |
| [Development deployment](docs/dev/development-deployment.md) | Docker Compose development setup and chat widget test flow. |
| [Production deployment](docs/prod/production-deployment.md) | Production-style Compose setup, build flow, config requirements, and validation. |

The deploy entrypoints are `scripts/deploy-local.sh`, `scripts/deploy-dev.sh`, and `scripts/deploy-prod.sh`. Each script has built-in `--help`.

## Features

- **Multi Channel Support**  
  Support for multiple communication channels. Currently live chat is available with more channels coming soon.
- **Admin/Agent Roles**  
  Role-based access control with distinct permissions for administrators and support agents.
- **Internationalization Support**  
  Multi-language support for global customer support teams and customers.
- **Canned Responses**  
  Save frequently used messages as templates for quick and consistent customer responses.
- **Live Chat SDK**  
  Easy-to-integrate SDK for embedding live chat functionality into any web application.
- **Audit System**  
  Complete activity tracking and logging for compliance, accountability, and performance monitoring.
- **Live Chat Widget Customization**  
  Fully customizable chat widget to match your brand colors, styling, and user experience.
- **Auto Assignments**  
  Intelligent conversation routing and automatic assignment to available agents based on custom rules.
- **Out of Hours Message**  
  Automated responses for customers contacting support outside business hours.
- **Pre-Chat Form**  
  Customizable forms to collect customer information before starting a chat session.
