kubectl delete svc jenkins -n jenkins
kubectl delete deployment jenkins -n jenkins
kubectl delete pvc jenkins-pvc -n jenkins
kubectl delete pv jenkins-pv
kubectl delete namespace jenkins

kubectl get all -n jenkins

kubectl get pv | grep jenkins

