// ArchUnit boundary test — Java architectural layer enforcement
// Dependency: com.tngtech.archunit:archunit-junit5:1.3.0
// Run: Executes as a standard JUnit 5 test — integrates into existing `mvn test` / `gradle test`
// CI: No additional CI config needed; runs with your test suite
//
// Layer direction: domain -> repository -> service -> controller
// Each layer may only access layers below it in the stack.
// Customize package patterns (..domain.., ..repository.., etc.) to match your project structure.

package com.example.architecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

// REMEDIATION: When a test fails, the output shows the violating import path.
// Example: "Layer 'Domain' is not allowed to access layer 'Controller'"
// Fix: Move shared logic to a lower layer, or introduce an interface in the lower layer
// that the upper layer implements.

@AnalyzeClasses(packages = "com.example", importOptions = ImportOption.DoNotIncludeTests.class)
public class ArchitectureBoundaryTest {

    @ArchTest
    static final ArchRule layer_dependencies_are_respected = layeredArchitecture()
        .consideringOnlyDependenciesInLayers()
        .layer("Domain").definedBy("..domain..")
        .layer("Repository").definedBy("..repository..", "..persistence..")
        .layer("Service").definedBy("..service..")
        .layer("Controller").definedBy("..controller..", "..api..", "..web..")

        .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
        .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
        .whereLayer("Repository").mayOnlyBeAccessedByLayers("Service")
        .whereLayer("Domain").mayOnlyBeAccessedByLayers("Repository", "Service", "Controller")
        .because("Dependencies must flow: Domain -> Repository -> Service -> Controller. "
            + "If you need data from a higher layer, expose it through an interface in the lower layer.");

    @ArchTest
    static final ArchRule domain_must_not_depend_on_infrastructure = noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat().resideInAnyPackage(
            "..controller..", "..api..", "..web..",
            "..persistence..", "..infrastructure.."
        )
        .because("Domain classes must remain independent of infrastructure. "
            + "Use repository interfaces in domain, implementations in persistence/infrastructure.");
}
