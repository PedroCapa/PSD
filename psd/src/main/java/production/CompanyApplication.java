package production;

import io.dropwizard.Application;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;

import production.resources.Production;
import production.health.TemplateHealthCheck;

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
        //environment.jersey().register(
        //    new Departments());
        environment.healthChecks().register("template",
            new TemplateHealthCheck(configuration.template));
    }

}

