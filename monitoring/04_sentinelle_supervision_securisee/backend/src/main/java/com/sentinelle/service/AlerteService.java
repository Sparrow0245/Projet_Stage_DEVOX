package com.sentinelle.service;

import com.sentinelle.repository.AlertsRepository;
import com.sentinelle.model.Alert;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class AlertsService {

    @Autowired
    private AlertsRepository alertsRepository;

    public List<Alert> getActiveAlerts() {
        return alertsRepository.findByStatus("NEW");
    }
}
