#!/usr/bin/env python

from os import environ
from os.path import abspath, dirname, join
import sys

from e3.testsuite import Testsuite
from e3.testsuite.driver.diff import DiffTestDriver


class LibGNATdocExtractorDriver(DiffTestDriver):
    def run(self):
        exe_path = join(dirname(dirname(abspath(__file__))), ".objs", "test_extractor")
        configuration_file = join(
            self.test_env["test_dir"],
            "gnat.json"
            if "extractor_configuration" not in self.test_env
            else self.test_env["extractor_configuration"],
        )
        source_file = join(self.test_env["test_dir"], self.test_env["extractor_source"])

        self.shell([exe_path, configuration_file, source_file])


class GNATdocExecutableDriver(DiffTestDriver):
    def set_up(self):
        super().set_up()

        self.test_environ = environ
        self.test_environ["GNATDOC4"] = "gnatdoc"

    def run(self):
        script_path = join(self.test_env["test_dir"], "test.sh")

        self.shell(args=[script_path], env=self.test_environ)


class LibGNATdocTestsuite(Testsuite):
    """Testsuite for the LibGNATdoc library"""

    test_driver_map = {
        "extractor": LibGNATdocExtractorDriver,
        "executable": GNATdocExecutableDriver,
    }
    default_driver = "extractor"


if __name__ == "__main__":
    sys.exit(LibGNATdocTestsuite().testsuite_main())
