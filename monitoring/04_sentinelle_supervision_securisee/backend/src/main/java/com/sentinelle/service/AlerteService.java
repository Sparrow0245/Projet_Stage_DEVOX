package com.sentinelle.service;

import com.sentinelle.model.Alert;
import com.sentinelle.repository.AlertsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class AlerteService {

    @Autowired
    private AlertsRepository alertsRepository;

    public List<Alert> getAllAlerts() {
        return alertsRepository.findAll();
    }

    public Alert saveAlert(Alert alert) {
        return alertsRepository.save(alert);
    }
}
