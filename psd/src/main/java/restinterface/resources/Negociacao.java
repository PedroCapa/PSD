package restinterface.resources;

import restinterface.representations.Saying;

import com.google.common.base.Optional;

import javax.ws.rs.GET;
import javax.ws.rs.PUT;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.PathParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

@Path("/negociacao")
@Produces(MediaType.APPLICATION_JSON)
public class Negociacao {
    private String negociador;
    private List<Negocio> negotiations;

    public Negociacao(String negociador, List<Negocio> negotiations) {
        this.negociador = negociador;
        this.negotiations = negotiations;
    }

    public String getNegociador(){
        return this.negociador;
    }

    public List<Negocio> getNegotiations(){
        return this.negotiations;
    }    
}