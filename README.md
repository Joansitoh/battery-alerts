<p align="center">
  <img src="https://cdn-icons-png.flaticon.com/512/6295/6295417.png" width="100" />
</p>
<p align="center">
    <h1 align="center">BATTERY-ALERTS</h1>
</p>
<p align="center">
    <em>Linux battery alerts</em>
</p>
<p align="center">
	<img src="https://img.shields.io/github/license/Joansitoh/battery-alerts?style=flat&color=0080ff" alt="license">
	<img src="https://img.shields.io/github/last-commit/Joansitoh/battery-alerts?style=flat&logo=git&logoColor=white&color=0080ff" alt="last-commit">
	<img src="https://img.shields.io/github/languages/top/Joansitoh/battery-alerts?style=flat&color=0080ff" alt="repo-top-language">
	<img src="https://img.shields.io/github/languages/count/Joansitoh/battery-alerts?style=flat&color=0080ff" alt="repo-language-count">
<p>
<p align="center">
		<em>Developed with the software and tools below.</em>
</p>
<p align="center">
	<img src="https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?style=flat&logo=GNU-Bash&logoColor=white" alt="GNU%20Bash">
</p>
<hr>

## 🔗 Quick Links

> - [📍 Overview](#-overview)
> - [📦 Features](#-features)
> - [🚀 Getting Started](#-getting-started)
>   - [⚙️ Installation](#️-installation)
>   - [🤖 Running battery-alerts](#-running-battery-alerts)
>   - [🧪 Tests](#-tests)
> - [🛠 Project Roadmap](#-project-roadmap)
> - [🤝 Contributing](#-contributing)
> - [👏 Acknowledgments](#-acknowledgments)

---

## 📍 Overview

![Low battery notification](https://imgur.com/o4vQPIe.png)
![Charging battery notification](https://imgur.com/ubEpxui.png)
![DIscharging battery notification](https://imgur.com/uXlkGNg.png)

---

## 📦 Features

Batery notifications for modified desktop environments.

---

## 🚀 Getting Started

**_Requirements_**

Ensure you have the following dependencies installed on your system:

- **Shell**: `version x.y.z`
- **acpi**: `version 1.7.0`
- **notify-send**: `version 0.8.3`

### ⚙️ Installation

1. Clone the battery-alerts repository:

```sh
git clone https://github.com/Joansitoh/battery-alerts
```

2. Change to the project directory:

```sh
cd battery-alerts
```

3. Execute and follow the instructions in the installer script:

```sh
chmod +x installer.sh
./installer.sh
```

### 🤖 Running battery-alerts

You can use the `battery-alerts` command.

```sh
battery-alerts --help
battery-alerts --status
battery-alerts --start
```

### 🧪 Tests

To execute tests, run:

```sh
battery-alerts --run
```

---

## 🛠 Project Roadmap

- [x] `► Work fine`
- [ ] `► Work fine`

---

## 🤝 Contributing

Contributions are welcome! Here are several ways you can contribute:

- **[Submit Pull Requests](https://github.com/Joansitoh/battery-alerts/blob/main/CONTRIBUTING.md)**: Review open PRs, and submit your own PRs.
- **[Join the Discussions](https://github.com/Joansitoh/battery-alerts/discussions)**: Share your insights, provide feedback, or ask questions.
- **[Report Issues](https://github.com/Joansitoh/battery-alerts/issues)**: Submit bugs found or log feature requests for Battery-alerts.

<details closed>
    <summary>Contributing Guidelines</summary>

1. **Fork the Repository**: Start by forking the project repository to your GitHub account.
2. **Clone Locally**: Clone the forked repository to your local machine using a Git client.
   ```sh
   git clone https://github.com/Joansitoh/battery-alerts
   ```
3. **Create a New Branch**: Always work on a new branch, giving it a descriptive name.
   ```sh
   git checkout -b new-feature-x
   ```
4. **Make Your Changes**: Develop and test your changes locally.
5. **Commit Your Changes**: Commit with a clear message describing your updates.
   ```sh
   git commit -m 'Implemented new feature x.'
   ```
6. **Push to GitHub**: Push the changes to your forked repository.
   ```sh
   git push origin new-feature-x
   ```
7. **Submit a Pull Request**: Create a PR against the original project repository. Clearly describe the changes and their motivations.

Once your PR is reviewed and approved, it will be merged into the main branch.

</details>

---

## 👏 Acknowledgments

- Thanks to the fucking bspwm that did not show me even 1 notification when I ran out of battery and shut down without warning.

[**Return**](#-quick-links)

---
