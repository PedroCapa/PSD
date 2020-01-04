package restinterface;

import io.dropwizard.Application;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;

import restinterface.resources.Produtores;
import restinterface.health.TemplateHealthCheck;

public class CompanyApplication extends Application<CompanyConfiguration> {
    public static void main(String[] args) throws Exception {
        new CompanyApplication().run(args);
    }

    @Override
    public String getName() { return "Company"; }

    @Override
    public void initialize(Bootstrap<CompanyConfiguration> bootstrap) { }

    @Override
    public void run(CompanyConfiguration configuration,
                    Environment environment) {
        //Colocar ai em vez de Departments as Productions
        environment.jersey().register(
            new Produtores());
        environment.healthChecks().register("template",
            new TemplateHealthCheck(configuration.template));
    }

}

