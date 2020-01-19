package main.java.restinterface.resources;

import main.java.restinterface.representations.Prod;
import main.java.restinterface.representations.Neg;
import main.java.restinterface.representations.Imp;

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

import main.proto.Protos.AceptedNegotiation;
import main.proto.Protos.Production;
import main.proto.Protos.ResponseImporterDropwizard;
import main.proto.Protos.ImporterDropwizard;
import main.proto.Protos.ResponseNegotiationDropwizard;
import main.proto.Protos.NegotiationDropwizard;

@Path("/catalogos")
@Produces(MediaType.APPLICATION_JSON)
public class Catalogos{

    @GET
    @Path("/importador/{name}")
    public List<Imp> getImportador(@PathParam("name") String name){
        System.out.println("Pediu um pedido de um importador");
        List<Imp> n = new ArrayList<>();
        try{
            AskServer ask = new AskServer();
            List<ImporterDropwizard> prod = ask.askServersImportador(name);        
            
            for(ImporterDropwizard neg: prod){
                n.add(new Imp(neg.getFabricante(), neg.getProductName(), neg.getPrice(), neg.getAmount(), neg.getData(), neg.getState()));
            }
        }
        catch(Exception e){
            System.out.println(e.getMessage());
        }
        finally{
            return n;
        }
    }

    @GET
    @Path("/produtor/{name}")
    public List<Prod> getProdutor(@PathParam("name") String name){
        System.out.println("Pediu um pedido de um produto: " + name);
        List<Prod> p = new ArrayList<>();
        try{
            System.out.println("Vou pedir");
            AskServer ask = new AskServer();
            List<Production> prod = ask.askServerProduto(name);        
            
            System.out.println("Recebi tudo");

            for(Production pro: prod){
                p.add(new Prod(pro.getProductName(), pro.getMin(), pro.getMax(), pro.getPrice(), pro.getData()));
            }
        }
        catch(Exception e){
            e.printStackTrace();
        }
        finally{
            return p;
        }
    }

    @GET
    @Path("/negocio/{fabricante}/{produto}")
    public List<Neg> getNegocio(@PathParam("fabricante") String fabricante, @PathParam("produto") String produto){
        System.out.println("Pediu um pedido de um negocio de um produto");
        List<Neg> n = new ArrayList<>();
        try{
            AskServer ask = new AskServer();
            List<NegotiationDropwizard> prod = ask.askServerNegocio(fabricante, produto);        
            
            for(NegotiationDropwizard neg: prod){
                n.add(new Neg(neg.getUsername(), neg.getPrice(), neg.getAmount(), neg.getData(), neg.getState()));
            }
        }
        catch(Exception e){
            System.out.println(e.getMessage());
        }
        finally{
            return n;
        }
    }
}