#!/usr/bin/env python

from os import environ
from os.path import abspath, dirname, join
import sys
from typing import List

from e3.testsuite import Testsuite
from e3.testsuite.driver.diff import (
    DiffTestDriver,
    OutputRefiner,
    ReplacePath,
    Substitute,
)


class ALSHelperDriver(DiffTestDriver):
    def run(self):
        exe_path = join(dirname(dirname(abspath(__file__))), ".objs", "test_als_helper")
        self.shell([exe_path, "default.gpr", "locations.json"])


class LibGNATdocExtractorDriver(DiffTestDriver):
    def run(self):
        exe_path = join(dirname(dirname(abspath(__file__))), ".objs", "test_extractor")
        configuration_file = join(
            self.test_env["test_dir"],
            (
                "gnat.json"
                if "extractor_configuration" not in self.test_env
                else self.test_env["extractor_configuration"]
            ),
        )
        source_files = []
        if "extractor_sources" in self.test_env:
            source_files = self.test_env["extractor_sources"]

        else:
            source_files.append(self.test_env["extractor_source"])

        # Resolve full path to source file
        source_files = [join(self.test_env["test_dir"], file) for file in source_files]

        for source_file in source_files:
            self.shell([exe_path, configuration_file, source_file])


class GNATdocExecutableDriver(DiffTestDriver):
    """This driver runs 'test.sh' script in the test directory and compares
    output with test.out file.
    """

    def set_up(self):
        super().set_up()

        self.test_environ = environ
        self.test_environ["GNATDOC4"] = "gnatdoc"

    def run(self):
        script_path = join(self.test_env["test_dir"], "test.sh")

        self.shell(args=["bash", script_path], env=self.test_environ)

    @property
    def output_refiners(self) -> List[OutputRefiner]:
        return super(GNATdocExecutableDriver, self).output_refiners + [
            ReplacePath(self.working_dir(), "<<WORKING_DIR>>"),
            Substitute("<<WORKING_DIR>>\\.\\", "<<WORKING_DIR>>/./"),
            Substitute("<<WORKING_DIR>>\\", "<<WORKING_DIR>>/"),
        ]


class LibGNATdocTestsuite(Testsuite):
    """Testsuite for the LibGNATdoc library"""

    test_driver_map = {
        "extractor": LibGNATdocExtractorDriver,
        "executable": GNATdocExecutableDriver,
        "als_helper": ALSHelperDriver,
    }
    default_driver = "extractor"


if __name__ == "__main__":
    sys.exit(LibGNATdocTestsuite().testsuite_main())
