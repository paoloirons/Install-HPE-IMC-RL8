# Install HPE IMC on Rocky Linux 8

Quattro script sequenziali per preparare un host Rocky Linux 8, predisporre MariaDB, avviare l'installer HPE IMC e gestire i controlli post-installazione.

## Uso

```bash
sudo ./01_prep_os.sh
sudo ./02_install_db.sh
sudo ./03_install_imc.sh
sudo ./04_post_install.sh status
```

Variabili principali: `HOSTNAME_FQDN`, `EXPECTED_IP`/`SERVER_IP`, `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_HOST`, `HTTP_PORT`, `HTTPS_PORT`, `IMC_BIN`.

### Sicurezza

Lo script `01_prep_os.sh` **non disabilita più SELinux e firewalld per default**. Per riprodurre il vecchio scenario lab/trial usa esplicitamente `sudo LAB_MODE=1 ./01_prep_os.sh`.

`02_install_db.sh` genera una password casuale quando `DB_PASS` non è fornita e salva le credenziali in `/root/imc-db.env` con permessi `0600`. `03_install_imc.sh` le carica automaticamente.

> Gli script non sostituiscono la matrice di compatibilità/licenza HPE IMC della specifica release installata.
