#!/usr/bin/env python3

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


class LibGNATdocTestsuite(Testsuite):
    """Testsuite for the LibGNATdoc library"""

    test_driver_map = {"extractor": LibGNATdocExtractorDriver}
    default_driver = "extractor"


if __name__ == "__main__":
    sys.exit(LibGNATdocTestsuite().testsuite_main())
