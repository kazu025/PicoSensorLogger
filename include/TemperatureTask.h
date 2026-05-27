#pragma once

#include "AEADT7410.h"
#include "AQM0802.h"
#include "EventLogger.h"

struct TemperatureTaskContext {
    AEADT7410* sensor;
    AQM0802* lcd;
    EventLogger* logger;
    QueueHandle_t display_mode_queue;
};

void temperature_task(void* param);
