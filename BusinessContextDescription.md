# 📘 Business Context Description — FitBand Cloud Project

## 1. Project Summary

**FitBand Cloud** is a prototype IoT ecosystem that emulates how fitness wearables interact with cloud services.  
It demonstrates secure device-to-cloud communication, data ingestion, and real-time monitoring — without needing physical hardware.

The system consists of:
- A **mock fitness band simulator** that sends signed telemetry (heart rate, steps, motion, battery).
- A **NestJS backend** that validates, stores, and streams this data to connected clients.
- A **PostgreSQL database** for time-series storage and analytics.
- Optional integration with an **MQTT broker** to illustrate IoT message routing.

This platform allows developers, students, and researchers to experiment with IoT concepts, backend APIs, and cloud deployments safely and cost-effectively.

---

## 2. Problem Statement

Modern fitness platforms (Fitbit, Garmin, Apple Health) rely on complex IoT infrastructures that are difficult for students and small teams to access.  
Developing or testing such systems usually requires:
- Physical devices with proprietary firmware,
- Paid API subscriptions or SDKs,
- Scalable backend environments.

**FitBand Cloud** solves this by providing an *open, simulated, and educational environment* for experimenting with:
- Secure telemetry ingestion,
- Cloud data storage,
- REST API design,
- Real-time WebSocket and MQTT communication.

---

## 3. Project Goals

- ✅ Simulate an IoT fitness band using Node.js telemetry generator.  
- ✅ Build a secure backend with NestJS + PostgreSQL.  
- ✅ Visualize data via Swagger and WebSocket clients.  
- ✅ Document the architecture using C4 model.  
- ✅ Deployable to Azure using Docker containers.  

---

## 4. Stakeholders

| Role | Description | Needs |
|------|--------------|-------|
| **Developers / Students** | Users testing the system or building integrations | Simple, documented API with realistic data |
| **Educators / Mentors** | Evaluate IoT architecture understanding | Clear design (C4), working demo |
| **Researchers / Data Scientists** | Want clean time-series datasets | Downloadable telemetry history |
| **System Admins / DevOps** | Manage the cloud environment | Containerized, monitored, cost-effective setup |

---

## 5. Use Cases

| ID | Title | Description |
|----|--------|-------------|
| UC-1 | **Send Telemetry** | A mock device sends signed telemetry data via HTTP (`POST /ingest`) to the cloud backend. |
| UC-2 | **Store Data** | The backend verifies, parses, and stores telemetry in PostgreSQL with timestamps and session info. |
| UC-3 | **Stream Live Data** | The backend emits live telemetry updates via WebSockets to subscribed dashboards. |
| UC-4 | **Query Latest Metrics** | A client requests the most recent telemetry record for a device (`GET /devices/:id/latest`). |
| UC-5 | **View History** | A user retrieves telemetry within a time range or session (`GET /devices/:id/sessions/:sid/telemetry`). |
| UC-6 | **Start/Stop Session** | A client starts or stops a training session for grouping telemetry records. |
| UC-7 | **Command Device** | A client sends a “vibrate” or “ping” command via REST → WebSocket bridge to the simulator. |
| UC-8 | **Monitor System Health** | Admin queries `/health/liveness` and `/health/readiness` endpoints to check status. |
| UC-9 | **MQTT Publish (Optional)** | A simulator publishes telemetry to an MQTT topic, which is bridged to `/ingest`. |

---

## 6. User Stories

| ID | As a... | I want to... | So that... |
|----|----------|--------------|-------------|
| US-1 | Developer | Test my IoT backend without physical devices | I can validate data ingestion and storage logic |
| US-2 | Student | Learn how secure device-to-cloud communication works | I understand HMAC, API keys, and message signing |
| US-3 | Data Analyst | Retrieve and visualize fitness telemetry | I can analyze activity trends |
| US-4 | Instructor | Demonstrate real-time data streaming | I can teach IoT protocols like HTTP, WS, and MQTT |
| US-5 | Team Lead | Deploy the project to Azure easily | I can manage and scale it in a cloud environment |

---

## 7. System Overview

**Main data flow:**
1. Device simulator generates JSON telemetry with timestamp and metrics.
2. Simulator signs data using HMAC(secret) and sends to `/ingest`.
3. Backend verifies signature → saves record to DB → emits event via WebSocket.
4. Clients access Swagger to test APIs or subscribe to real-time data.
5. Optional MQTT broker allows alternative IoT-style message routing.

**Core entities:**
- **Device** → represents a physical band with its own secret.
- **Session** → represents a workout or activity window.
- **Telemetry** → represents individual sensor readings.

---

## 8. Expected Outcomes

- Working prototype showing full IoT lifecycle: **device → backend → database → live stream**.  
- Interactive **Swagger UI** replacing Postman collection.  
- **Dockerized** local setup and **Azure-ready** deployment.  
- Realistic telemetry dataset suitable for further data analytics or AI models.  

---

## 9. Future Extensions

- Integrate **MQTT → Kafka → Analytics pipeline** for scalability.
- Add **Next.js dashboard** visualizing telemetry charts.
- Implement **ML module** for anomaly detection or workout intensity classification.
- Integrate **mobile notifications** for “live coaching” use case.

---

## 10. Summary

**FitBand Cloud** demonstrates how IoT, backend development, and DevOps intersect.  
It bridges the gap between hardware-dependent IoT systems and accessible cloud simulations,  
making it an ideal educational project for developers, students, and researchers interested in secure data pipelines and real-time systems.

---
