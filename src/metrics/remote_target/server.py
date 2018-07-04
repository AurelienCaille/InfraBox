#!/usr/bin/env python
import sys
import time
import os
import requests

from prometheus_client import Gauge, start_http_server, parser

"""
A little python web server which collects datas from a distant Infrabox Prometheus instance and recreate them
to be used as a target by our main Prometheus Instance
For now it does not support histogram metrics, as we only get metrics created by our collector
server and the Node Exporter.
Quantiles and bucket are apparently not managed well with this kind of Federate scraping
Check https://prometheus.io/docs/prometheus/latest/federation/ for more details
"""


class ScrapedGauge:
    def __init__(self, name, labels):
        self.name = name
        self.labels = tuple(labels[:])
        self._gauge = Gauge(name, "A identified metric found during scraping the /federate web page", list(self.labels))

    def update(self, label_values, value):
        self._gauge.labels(* self._label_value_iterator(label_values)).set(value)

    def _label_value_iterator(self, label_values):
        for label in self.labels:
            yield label_values.get(label)


class MetricManager:
    def __init__(self):
        self.metrics = dict()

    def process(self, parsed_metric):
        """
        Set the values for the given family metric
        and create it if it has never been encountered before
        """
        metric = self.metrics.get(parsed_metric.name)
        if metric:
            MetricManager._update(metric, parsed_metric)
        else:
            MetricManager._update(self._create(parsed_metric), parsed_metric)

    @staticmethod
    def _update(metric, parsed_metric):
        """
        Analyze the parsed labels and values and update the
        corresponding metric

        :param metric:
        :param parsed_metric:
        :return:
        """
        for sample in parsed_metric.samples:
            metric.update(sample[1], sample[2])

    def _create(self, parsed_metric):
        """
        Analyze the parsed metric to create a proper metric

        :param parsed_metric:
        :return:
        """
        labels = tuple(parsed_metric.samples[0][1].keys())
        new_metric = ScrapedGauge(parsed_metric.name, labels)
        self.metrics[parsed_metric.name] = new_metric
        return new_metric


def start_server(init_wait_time, threshold, port):
    """
    A little utility which try to launch the server, is used at least one time.
    Could be use in the future in the TRY main statement if http server stops unexceptedly
    :param init_wait_time:  Time to wait the first time, is incremented at each fail
    :param threshold:       When the wait time get to this value we stop trying
    :param port:            Port on which open the server
    """
    print("Starting server on port : {}".format(port))
    while init_wait_time <= threshold:
        try:
            start_http_server(int(port))
            return True
        except OSError:
            # TODO find the right log where to write it
            sys.stderr.write(
                "Unable to start the server on the {} port\nI'll wait {}s and try again".format(port, init_wait_time))
            time.sleep(init_wait_time)
            init_wait_time += 1
    return False




def main():
    # getting the env variables
    server_port = os.environ.get('INFRABOX_PORT', 8044)
    distant_prom_addr = os.environ.get('DISTANT_PROM_ADDR', "http://localhost:9090")

    url_to_scrape = distant_prom_addr + '''/federate?match[]={__name__=~"..*"}'''

    # When restarting or starting on a docker container, the port can be still used at the first try
    if not start_server(2, 5, server_port):
        return 1

    # These are the metrics of the python collector server itself
    skipped_metrics = ('up', "scrape_samples_post_metric",
        "scrape_duration_seconds",
        "python_info",
        "process_virtual_memory_bytes",
        "process_start_time_seconds",
        "process_resident_memory_bytes",
        "process_open_fds",
        "process_max_fds",
        "process_cpu_seconds",
        'process_cpu_seconds_total')

    metric_manager = MetricManager()
    while running:
        response = requests.get(url_to_scrape)
        families = parser.text_string_to_metric_families(response.content.decode("utf-8"))
        for family in families:
            if family.name not in skipped_metrics:
                metric_manager.process(family)


        time.sleep(1.9)


if __name__ == '__main__':
    running = True
    main()

