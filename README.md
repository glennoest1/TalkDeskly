# TalkDeskly

Modern, real-time chat application with embeddable components. Built for scalability and seamless integration.

TalkDeskly is a single-binary application built with Go and React.

![TalkDeskly Demo](docs/images/hero.png)

Visit [talkdeskly.com](https://talkdeskly.com) for more info. Check out the [**Live demo**](https://demo.talkdeskly.com/).

> **CAUTION:** This project is currently in **development**. Features and APIs may change and are not yet fully tested.

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

## Docker Compose Deployment

Deployment guides are in [docs/deploy](docs/deploy/README.md).

| Mode | Guide | Compose file |
| --- | --- | --- |
| Development | [Development deployment](docs/deploy/dev/development-deployment.md) | `docker-compose.dev.yml` |
| Production | [Production deployment](docs/deploy/prod/production-deployment.md) | `docker-compose.prod.yml` |

Use development mode for local work with hot reload, MailHog, and separate frontend/widget containers. Use production mode when testing the compiled backend image that serves the admin frontend and widget SDK.
