
# 🚀 Redis High Availability (HA) Infrastructure – Automated Deployment

**Terraform + Ansible + Jenkins CI/CD**

This project provisions a fully automated **Redis High Availability setup** using:

* **Terraform** – AWS VPC, Subnets, EC2, Security Groups, Bastion
* **Ansible** – Configure Redis Master & Replica
* **Jenkins Pipeline** – End-to-end CI/CD deployment & testing

---

# 🖼️ Infrastructure Diagram (ADD IMAGE HERE)

> **📌 Infrastructure Diagram**


<img width="658" height="720" alt="image" src="https://github.com/user-attachments/assets/3c31a08b-a9a9-4cdb-9759-9078a270ae55" />

---

# 📌 Project Features

✔ Fully automated Redis HA deployment
✔ Bastion-based secure SSH tunneling
✔ Private Redis Master + Replica
✔ Automatic replication configuration
✔ Jenkins-based CI/CD pipeline
✔ Built-in Redis PING health check

---

# 🏗️ Architecture Overview (Text-based)

```
                ┌───────────────────────────┐
                │       Jenkins Server       │
                └──────────────┬────────────┘
                               │ CI/CD Trigger
                               ▼
                 ┌─────────────────────────┐
                 │        Terraform         │
                 └─────────────┬───────────┘
                               │ Creates
                               ▼
       ┌──────────────────────────────────────────────────┐
       │                     AWS VPC                      │
       │                                                  │
       │  ┌──────────────┐          ┌──────────────────┐  │
       │  │   Bastion     │  SSH     │ Redis Master     │  │
       │  │ 13.135.72.10  ├─────────▶│ 10.0.2.210       │  │
       │  └──────────────┘          └──────────────────┘  │
       │           │                          ▲           │
       │           ▼                          │           │
       │  ┌──────────────────┐                │           │
       │  │ Redis Replica     │◀──────────────┘           │
       │  │ 10.0.3.150        │                            │
       │  └──────────────────┘                            │
       └──────────────────────────────────────────────────┘
```

---

# 📂 Project Structure

```
redis-ha-infra/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── redis-demo-key.pem
│
├── ansible/
│   ├── inventory/
│   │   └── hosts.ini
│   ├── site.yml
│   ├── ansible.cfg
│   └── templates/
│       └── redis.conf.j2
│
├── Jenkinsfile
└── README.md
```

---

# 🔧 Jenkins Pipeline Summary

### **Stage 1: Checkout Repo**

Clones GitHub repository.

### **Stage 2: Terraform Apply**

* Initializes Terraform
* Applies infrastructure
* Returns master/replica/bastion IP outputs

### **Stage 3: Generate Inventory**

Creates inventory dynamically using Terraform outputs.

### **Stage 4: Install Redis via Ansible**

Sets up:

* Redis Master
* Redis Replica
* Replication configuration
* Protected-mode disabled

### **Stage 5: Redis Testing**

Jenkins performs:

```
redis-cli ping
```

On both Master & Replica via Bastion using ProxyCommand.

---

# 🧪 Manual Verification (Real Commands)

## 1️⃣ SSH into Redis Master (via Bastion)

```
ssh -i ~/redis-demo-key.pem ubuntu@35.179.132.203
```

### Expected:

```
ubuntu@ip-10-0-1-109:~$ 
```

---

## 2️⃣ SSH into Redis Replica (via Bastion)

```
ssh -i ~/redis-demo-key.pem ubuntu@10.0.3.38
```

---

## 3️⃣ Check Redis Master Status

```
redis-cli ping
```

Expected:

```
PONG
```

---

## 4️⃣ Replication Status from Master

```
redis-cli info replication
```

Expected:

```
role:master
connected_slaves:1
slave0:ip=10.0.3.150,state=online
```

---

## 5️⃣ Replica Sync Status

```
redis-cli info replication
```

Expected:

```
role:slave
master_host:10.0.2.210
master_link_status:up
```

---

## 6️⃣ Replication Data Test

### On Master:

```
redis-cli set demo:test "hello-replica"
```

### On Replica:

```
redis-cli get demo:test
```

Expected:

```
"hello-replica"
```

---

# 🎉 Final Notes

✔ Full Redis HA setup automated
✔ No manual infra creation
✔ Robust Jenkins CI/CD
✔ Verified Master–Replica replication
✔ Production-ready patterns

