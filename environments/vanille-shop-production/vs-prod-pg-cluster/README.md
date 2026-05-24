Das ist ein klassisches CNPG-Problem. Die häufigsten Ursachen:

1. Secret wurde rotiert, CNPG hat es nicht übernommen
Der 1Password-Operator updated das Kubernetes Secret, aber CNPG synct das Passwort nicht automatisch in PostgreSQL. CNPG watched zwar Secrets, aber der Reconcile-Loop kann das verpassen.

Prüfen:


# Was steht im Secret?
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.password}' | base64 -d

# Was hat PostgreSQL aktuell?
kubectl exec -n <namespace> <pod> -- psql -U postgres -c "\du <username>"
# (zeigt aber kein Passwort — nur ob der User existiert)
2. Cluster wurde aus Backup wiederhergestellt
Beim Recovery nimmt CNPG die Passwörter aus dem Backup-Snapshot. Die Secrets im Cluster können inzwischen andere Werte haben.

3. Managed Role Reconciliation erzwingen


# CNPG zwingt zu neuem Passwort-Sync wenn man die Annotation setzt:
kubectl annotate cluster <cluster-name> -n <namespace> \
  cnpg.io/reconciliationLoop="enabled" --overwrite
4. Passwort direkt in PostgreSQL zurücksetzen (schnellster Fix):


kubectl exec -n <namespace> <primary-pod> -- \
  psql -U postgres -c "ALTER USER <username> WITH PASSWORD '<neues-passwort>';"
In deinem Setup mit 1Password-Operator würde ich zuerst prüfen ob Secret-Inhalt und was CNPG deployed hat übereinstimmen — Recovery-Szenarien sind da die häufigste Ursache.