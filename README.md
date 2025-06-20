# SOC Lab IPG: TheHive + Shuffle + MISP + Wazuh

This repository builds a complete Security Operations Center (SOC) lab using
four open source components: **TheHive**, **Shuffle**, **MISP** and **Wazuh**.
It is intended for demonstration and learning purposes so you can practice
incident response automation, threat intelligence and security monitoring on a
single server.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Accessing the Lab](#accessing-the-lab)
- [Recommended Hardware](#recommended-hardware)
- [References](#references)
- [License](#license)
- [Author](#author)

---

## Prerequisites

- **Ubuntu 24.04 LTS** as the host operating system
- Internet access to download Docker images
- Ability to run commands with **sudo** privileges

---

## Installation

### What `deploy.sh` does

1. Updates the host and installs base dependencies
2. Installs Docker and Docker Compose
3. Downloads and starts containers for **TheHive** (with Elasticsearch),
   **Shuffle**, **MISP** and **Wazuh**
4. Detects the VM IP address and configures service URLs
5. Creates some demo data inside TheHive and MISP

### Running the script

```bash
git clone https://github.com/VagnerBomJesus/soc-lab-ipg.git
cd soc-lab-ipg
chmod +x deploy.sh
./deploy.sh
```

The deployment takes several minutes. When finished, the script prints the URLs
for each service.

---

## Accessing the Lab

Replace `<YOUR_IP>` with the IP address displayed at the end of the installation.

### TheHive – Incident Management
- **URL:** `http://<YOUR_IP>:9000`
- **User:** `admin@thehive.local`
- **Password:** `secret`

### Shuffle – SOAR
- **URL:** `http://<YOUR_IP>:3001`
- **User:** `admin@shuffle.local`
- **Password:** defined on first login

### MISP – Threat Intelligence
- **URL:** `http://<YOUR_IP>:8080`
- **User:** `admin@admin.test`
- **Password:** `admin`

### Wazuh Dashboard
- **URL:** `https://<YOUR_IP>:8443`
- **Credentials:** default Wazuh credentials created during setup

⚠️ **Important:** Change all default passwords after your first login to keep the
lab secure.

---

## Recommended Hardware

| Resource            | Minimum            | Notes                                           |
|--------------------|--------------------|-------------------------------------------------|
| CPU                | 4 vCPUs            | More cores improve overall performance          |
| RAM                | 8 GB               | 12 GB or more provides smoother operation       |
| Storage            | 40 GB SSD          | Elasticsearch and MISP can consume disk space   |
| OS                 | Ubuntu 24.04 LTS   | Tested with the provided `deploy.sh`            |
| Network            | Internet access    | Required to pull Docker images                  |

For heavier workloads consider **16 GB of RAM and 100 GB of storage**.

---

## References

- [TheHive Project](https://thehive-project.org/)
- [Shuffle SOAR](https://shuffler.io/)
- [MISP Project](https://www.misp-project.org/)
- [Wazuh](https://wazuh.com/)
- [NUKIB MISP Docker](https://github.com/NUKIB/misp)

---

## License

This project is licensed under the MIT License. See the file
[LICENSE](LICENSE) for full details.

## Author

<table>
  <tr>
  <td align="left">
      <a href="https://github.com/VagnerBomJesus">
        <img src="https://github.com/VagnerBomJesus.png?size=100" width="100px;" alt="Foto do Vagner Bom Jesus no GitHub"/><br>
        <sub>
          <b>Vagner Bom Jesus</b>
        </sub>
      </a>
    </td> 
 </tr>
</table>
